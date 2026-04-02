(() => {
  // ../../js/src/toc.js
  function getOffsetTop(e) {
    if (!e) return 0;
    return getOffsetTop(e.offsetParent) + e.offsetTop;
  }
  function scrollTocToActive() {
    let fileNameWHash = window.location.href.split("/").pop();
    let fileName = fileNameWHash.split("#")[0];
    let tocEntry = document.querySelector(
      '#ptx-toc a[href="' + fileName + '"]'
    );
    if (!tocEntry) return;
    let tocEntryTop = 0;
    if (fileNameWHash.includes("#")) {
      let tocEntryWHash = document.querySelector(
        '#ptx-toc a[href="' + fileNameWHash + '"]'
      );
      if (tocEntryWHash) {
        tocEntry.closest("li").querySelectorAll("li").forEach((li) => {
          li.classList.remove("active");
        });
        tocEntryWHash.closest("li").classList.add("active");
        tocEntryTop = getOffsetTop(tocEntryWHash);
      }
    }
    if (!tocEntryTop) {
      tocEntryTop = getOffsetTop(tocEntry);
    }
    tocEntry.closest("li").classList.add("active");
    let toc = document.querySelector("#ptx-toc");
    let tocTop = getOffsetTop(toc);
    toc.scrollTop = tocEntryTop - tocTop - 0.4 * self.innerHeight;
  }
  function toggletoc() {
    const thesidebar = document.getElementById("ptx-sidebar");
    if (thesidebar.classList.contains("hidden") || thesidebar.classList.contains("visible")) {
      thesidebar.classList.toggle("hidden");
      thesidebar.classList.toggle("visible");
    } else if (thesidebar.offsetParent === null) {
      thesidebar.classList.toggle("visible");
    } else {
      thesidebar.classList.toggle("hidden");
    }
    scrollTocToActive();
  }
  function samePageLink(a) {
    if (!(a instanceof HTMLAnchorElement)) return false;
    try {
      const linkUrl = new URL(a.href, document.baseURI);
      const currentUrl = new URL(window.location.href);
      const sameDocument = linkUrl.origin === currentUrl.origin && linkUrl.pathname === currentUrl.pathname && linkUrl.search === currentUrl.search;
      return sameDocument && !!linkUrl.hash;
    } catch (e) {
      return false;
    }
  }
  function getTOCItemType(item) {
    for (let className of item.classList) {
      if (className !== "toc-item" && className.length > 3 && className.slice(0, 4) === "toc-")
        return className.slice(4);
    }
    return "";
  }
  function getTOCItemDepth(item) {
    let depth = 0;
    let curParent = item.closest(".toc-item-list");
    while (curParent !== null) {
      depth++;
      curParent = curParent.parentElement.closest(".toc-item-list");
    }
    return depth;
  }
  function toggleTOCItem(expander) {
    let listItem = expander.closest(".toc-item");
    listItem.classList.toggle("expanded");
    let expanded = listItem.classList.contains("expanded");
    let itemType = getTOCItemType(listItem);
    if (expanded) {
      expander.title = "Close" + (itemType !== "" ? " " + itemType : "");
    } else {
      expander.title = "Expand" + (itemType !== "" ? " " + itemType : "");
    }
    for (const childUL of listItem.querySelectorAll(
      ":scope > ul.toc-item-list"
    )) {
      for (const childItem of childUL.querySelectorAll(
        ":scope > li.toc-item"
      )) {
        if (expanded) {
          childItem.classList.add("visible");
          childItem.classList.remove("hidden");
        } else {
          childItem.classList.remove("visible");
          childItem.classList.add("hidden");
        }
      }
    }
  }
  function initToc() {
    const thetocbutton = document.getElementsByClassName("toc-toggle")[0];
    if (thetocbutton) {
      thetocbutton.addEventListener("click", (e) => {
        toggletoc();
        e.stopPropagation();
      });
    }
    if (getComputedStyle(document.documentElement).getPropertyValue(
      "--auto-collapse-toc"
    ) == "yes") {
      const sidebar = document.getElementById("ptx-sidebar");
      window.addEventListener("click", function(event2) {
        if (sidebar.classList.contains("visible")) {
          if (!event2.composedPath().includes(sidebar)) {
            toggletoc();
          }
        }
      });
      sidebar.addEventListener("click", function(event2) {
        if (samePageLink(event2.target.closest("a"))) {
          toggletoc();
        }
      });
      window.addEventListener("pageshow", (e) => {
        if (e.persisted) {
          sidebar.classList.remove("visible");
          sidebar.classList.add("hidden");
        }
      });
    }
  }
  function initFocusedToc() {
    if (document.querySelector(".ptx-toc.focused") === null) return;
    let maxDepth = 1e3;
    for (let className of document.querySelector(".ptx-toc").classList)
      if (className.length > 5 && className.slice(0, 5) === "depth")
        maxDepth = Number(className.slice(5));
    let preexpandedLevels = 1;
    let tocDataSet = document.querySelector(".ptx-toc").dataset;
    if (typeof tocDataSet.preexpandedLevels !== "undefined")
      preexpandedLevels = Number(tocDataSet.preexpandedLevels);
    let tocItems = document.querySelectorAll(
      ".ptx-toc ul.structural > .toc-item"
    );
    for (const tocItem of tocItems) {
      let hasChildren = tocItem.querySelector("ul.structural") !== null;
      let depth = getTOCItemDepth(tocItem);
      if (hasChildren && depth < maxDepth) {
        let expander = document.createElement("button");
        expander.classList.add("toc-expander");
        expander.classList.add("toc-chevron-surround");
        expander.title = "toc-expander";
        expander.innerHTML = '<span class="icon material-symbols-outlined" aria-hidden="true"></span>';
        tocItem.querySelector(".toc-title-box").append(expander);
        expander.addEventListener("click", () => {
          toggleTOCItem(expander);
        });
        let isActive = tocItem.classList.contains("contains-active") || tocItem.classList.contains("active");
        let preExpanded = isActive || depth < preexpandedLevels;
        let itemType = getTOCItemType(tocItem);
        if (preExpanded) {
          toggleTOCItem(expander);
        } else {
          expander.title = "Expand" + (itemType !== "" ? " " + itemType : "");
        }
      }
    }
    if (window.location.hash) {
      let hash = window.location.hash;
      let hashLink = document.querySelector(
        `.ptx-toc a[href$="${hash}"]`
      );
      if (hashLink) {
        let parentTocItem = hashLink.closest(".toc-item");
        while (parentTocItem && !parentTocItem.classList.contains("contains-active")) {
          parentTocItem.classList.add("contains-active");
          let expander = parentTocItem.querySelector(".toc-expander");
          if (expander) {
            if (!parentTocItem.classList.contains("expanded")) {
              toggleTOCItem(expander);
            }
          }
          parentTocItem = parentTocItem.parentElement.closest(".toc-item");
        }
      }
    }
  }
  function initScrollToc() {
    scrollTocToActive();
    window.onhashchange = scrollTocToActive;
  }

  // ../../js/src/knowl.js
  var SlideRevealer = class _SlideRevealer {
    static STATE = Object.freeze({
      INACTIVE: 0,
      CLOSING: 1,
      EXPANDING: 2
    });
    constructor(triggerElement, contentElement, animatedElement) {
      this.triggerElement = triggerElement;
      this.contentElement = contentElement;
      this.animatedElement = animatedElement;
      this.animation = null;
      this.animationState = _SlideRevealer.STATE.INACTIVE;
      this.triggerElement.addEventListener("click", (e) => this.onClick(e));
    }
    onClick(e) {
      if (e) e.preventDefault();
      this.animatedElement.style.overflow = "hidden";
      if (this.animationState === _SlideRevealer.STATE.CLOSING || !this.animatedElement.hasAttribute("open")) {
        this.animatedElement.setAttribute("open", "");
        this.triggerElement.setAttribute("open", "");
        this.contentElement.style.display = "";
        MathJax.typesetPromise().then(
          () => window.requestAnimationFrame(() => this.toggle(true))
        );
      } else if (this.animationState === _SlideRevealer.STATE.EXPANDING || this.animatedElement.hasAttribute("open")) {
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
      const padding = this.animatedElement.offsetHeight - this.animatedElement.clientHeight;
      const startPad = `${expanding ? 0 : padding}px`;
      const endPad = `${expanding ? padding : 0}px`;
      if (this.animation) this.animation.cancel();
      const animDuration = Math.max(
        Math.min(
          Math.abs(closedHeight - fullHeight) / 400 * 1e3,
          750
        ),
        250
      );
      this.animationState = expanding ? _SlideRevealer.STATE.EXPANDING : _SlideRevealer.STATE.CLOSING;
      this.animation = this.animatedElement.animate(
        {
          height: [startHeight, endHeight],
          paddingTop: [startPad, endPad],
          paddingBottom: [startPad, endPad]
        },
        { duration: animDuration, easing: "ease" }
      );
      this.animation.onfinish = () => {
        this.onAnimationFinish(expanding);
      };
      this.animation.oncancel = () => {
        this.animationState = _SlideRevealer.STATE.INACTIVE;
      };
    }
    onAnimationFinish(isOpen) {
      this.animation = null;
      this.animationState = _SlideRevealer.STATE.INACTIVE;
      if (!isOpen) {
        this.animatedElement.removeAttribute("open");
        this.triggerElement.removeAttribute("open");
      }
      this.animatedElement.style.overflow = "";
      if (!isOpen) this.contentElement.style.display = "none";
      if (isOpen) {
        let hasCallback = this.contentElement.querySelectorAll(
          "[data-knowl-callback]"
        );
        hasCallback.forEach((el) => {
          window[el.getAttribute("data-knowl-callback")](el, open);
        });
      }
    }
  };
  var LinkKnowl = class _LinkKnowl {
    static xrefCount = 0;
    static initializeXrefKnowl(knowlLinkElement) {
      if (knowlLinkElement.getAttribute("data-knowl-uid") === null) {
        return new _LinkKnowl(knowlLinkElement);
      }
    }
    constructor(knowlLinkElement) {
      this.linkElement = knowlLinkElement;
      this.outputElement = null;
      this.uid = _LinkKnowl.xrefCount++;
      knowlLinkElement.setAttribute("data-knowl-uid", this.uid);
      knowlLinkElement.setAttribute("role", "button");
      knowlLinkElement.setAttribute(
        "data-base-title",
        knowlLinkElement.getAttribute("title") || this.linkElement.textContent
      );
      knowlLinkElement.classList.add("knowl__link");
      this.updateLabels(false);
      knowlLinkElement.addEventListener(
        "click",
        this.handleLinkClick.bind(this)
      );
    }
    updateLabels(isVisible) {
      const verb = isVisible ? this.linkElement.getAttribute("data-close-label") || "Close" : this.linkElement.getAttribute("data-reveal-label") || "Reveal";
      const targetDescript = this.linkElement.getAttribute("data-base-title");
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
          if (this.outputElement.getBoundingClientRect().bottom > window.innerHeight)
            this.outputElement.scrollIntoView(false);
        }
      }
    }
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
    async getContent() {
      const contentURL = this.linkElement.getAttribute("data-knowl");
      const knowlContent = await fetch(contentURL).then((response) => response.text()).then((data) => {
        let knowlDoc = new DOMParser().parseFromString(
          data,
          "text/html"
        );
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
        content.then((tempContainer) => {
          if (loadingTimeout !== null) {
            clearTimeout(loadingTimeout);
          }
          setTimeout(() => {
            slideHandler.onClick();
            this.toggle();
          }, 100);
          const runestoneElements = tempContainer.querySelectorAll(
            ".ptx-runestone-container"
          );
          [...runestoneElements].forEach((e) => {
            const rsId = e.querySelector("[data-component]")?.id;
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
            )
          ].forEach((s) => {
            if (s.getAttribute("type") === null || s.getAttribute("type") === "text/javascript") {
              eval(s.innerHTML);
            }
          });
        }).catch((data) => {
          console.log(
            "Error fetching knowl content: " + data
          );
        });
      }
    }
  };
  function addKnowls(target) {
    const xrefs = target.querySelectorAll("[data-knowl]");
    for (const xref of xrefs) {
      LinkKnowl.initializeXrefKnowl(xref);
    }
    const bornHiddens = target.querySelectorAll(".born-hidden-knowl");
    for (const bhk of bornHiddens) {
      const summary = bhk.querySelector(":scope > summary");
      if (!summary) continue;
      const contents = bhk.querySelector(":scope > summary + *");
      new SlideRevealer(summary, contents, bhk);
    }
  }
  function initKnowls() {
    addKnowls(document);
  }

  // ../../js/src/lti-iframe-resizer.js
  function initLtiIframeResizer() {
    window.addEventListener("message", function(event2) {
      let edata = event2.data;
      if (typeof event2.data == "string" && event2.data.match(/lti\.frameResize/)) {
        edata = JSON.parse(event2.data);
      }
      if (edata.subject === "lti.frameResize") {
        if ("frame_id" in edata) {
          const el = document.getElementById(edata["frame_id"]);
          if (el) {
            el.style.height = edata.height + "px";
          }
          if (edata.wrapheight && document.getElementById(edata["frame_id"] + "wrap")) {
            document.getElementById(
              edata["frame_id"] + "wrap"
            ).style.height = edata.wrapheight + "px";
          }
        } else if ("iframe_resize_id" in edata) {
          const el = document.getElementById(
            edata["iframe_resize_id"]
          );
          if (el) {
            el.style.height = edata.height + "px";
          }
        } else {
          const iFrames = document.getElementsByTagName("iframe");
          for (const iFrame of iFrames) {
            if (iFrame.contentWindow === event2.source) {
              if (edata.height) {
                iFrame.height = edata.height;
                iFrame.style.height = edata.height + "px";
              }
              if (edata.width) {
                iFrame.width = edata.width;
                iFrame.style.width = edata.width + "px";
              }
              break;
            }
          }
        }
      }
    });
  }

  // ../../js/src/permalink.js
  async function copyPermalink(linkNode) {
    if (!navigator.clipboard) {
      console.log("Error: Clipboard API not available");
      return;
    }
    const elem = linkNode.parentElement;
    if (!linkNode) {
      console.log("Error: Something went wrong finding permalink URL");
      return;
    }
    const url = linkNode.href;
    const description = elem.getAttribute("data-description");
    const link = `<a href="${url}">${description}</a>`;
    const msgLink = `<a class="internal" href="${url}">${description}</a>`;
    const textFallback = description + " \r\n" + url;
    let copySuccess = true;
    try {
      await navigator.clipboard.write([
        new ClipboardItem({
          "text/html": new Blob([link], { type: "text/html" }),
          "text/plain": new Blob([textFallback], { type: "text/plain" })
        })
      ]);
    } catch (err) {
      console.log(
        "Permalink-to-clipboard using ClipboardItem failed, falling back to clipboard.writeText",
        err
      );
      copySuccess = false;
    }
    if (!copySuccess) {
      try {
        await navigator.clipboard.writeText(textFallback);
      } catch (err) {
        console.log(
          "Permalink-to-clipboard using clipboard.writeText failed",
          err
        );
        console.error("Failed to copy link to clipboard!");
        return;
      }
    }
    console.log(`copied '${url}' to clipboard`);
    const copiedMsg = document.createElement("p");
    copiedMsg.setAttribute("role", "alert");
    copiedMsg.className = "permalink-alert";
    copiedMsg.innerHTML = "Link to " + msgLink + " copied to clipboard";
    elem.parentElement.insertBefore(copiedMsg, elem);
    await new Promise((resolve) => setTimeout(resolve, 1500));
    copiedMsg.remove();
  }
  function initPermalinks() {
    const permalinks = document.querySelectorAll(".autopermalink > a");
    permalinks.forEach((link) => {
      link.addEventListener("click", function(event2) {
        event2.preventDefault();
        copyPermalink(link);
      });
    });
  }

  // ../../js/src/image-magnify.js
  function outermostMatchingAncestor(el, selector) {
    let match = null;
    let current = el.parentElement;
    while (current) {
      if (current.matches(selector)) {
        match = current;
      }
      current = current.parentElement;
    }
    return match;
  }
  function initImageMagnify() {
    const imgSelector = ".image-box > img:not(.draw_on_me):not(.mag_popup), .sbspanel > img:not(.draw_on_me):not(.mag_popup), figure > img:not(.draw_on_me):not(.mag_popup), figure > div > img:not(.draw_on_me):not(.mag_popup)";
    document.body.addEventListener("click", function(event2) {
      const img = event2.target.closest(imgSelector);
      if (!img) return;
      const container = document.createElement("div");
      container.setAttribute("style", "background:#fff;");
      container.setAttribute("class", "mag_popup_container");
      container.innerHTML = '<img src="' + img.src + '" style="width:100%" class="mag_popup"/>';
      let placement = outermostMatchingAncestor(
        img,
        ".image-box, .sbsrow, figure, li, .cols2 article:nth-of-type(2n)"
      );
      if (placement && placement.tagName === "ARTICLE") {
        const prev = placement.previousElementSibling;
        if (prev) {
          placement = prev.firstElementChild || prev;
        }
      }
      if (placement) {
        placement.parentNode.insertBefore(container, placement);
      }
    });
    document.body.addEventListener("click", function(event2) {
      if (event2.target.classList.contains("mag_popup")) {
        event2.target.parentNode.remove();
      }
    });
  }

  // ../../js/src/deprecated/scrollbar-width.js
  function getScrollbarWidth() {
    const outer = document.createElement("div");
    outer.style.visibility = "hidden";
    outer.style.width = "100px";
    outer.style.msOverflowStyle = "scrollbar";
    document.body.appendChild(outer);
    const widthNoScroll = outer.offsetWidth;
    outer.style.overflow = "scroll";
    const inner = document.createElement("div");
    inner.style.width = "100%";
    outer.appendChild(inner);
    const widthWithScroll = inner.offsetWidth;
    outer.parentNode.removeChild(outer);
    return widthNoScroll - widthWithScroll;
  }

  // ../../js/src/geogebra.js
  function calculatorOnload() {
    const toggle = document.getElementById("calculator-toggle");
    if (toggle) toggle.focus();
    const inputField = document.querySelector(
      "input.gwt-SuggestBox.TextField"
    );
    if (inputField) inputField.focus();
  }
  function initGeoGebra() {
    const scrollWidth = getScrollbarWidth();
    const calcOffsetR = 5;
    const calcOffsetB = 5;
    document.body.addEventListener("mouseover", function(event2) {
      if (!event2.target.closest("#geogebra-calculator canvas")) return;
      document.body.style.overflow = "hidden";
      document.documentElement.style.marginRight = "15px";
      const container = document.getElementById("calculator-container");
      if (container) {
        container.style.right = calcOffsetR + scrollWidth + "px";
        container.style.bottom = calcOffsetB + scrollWidth + "px";
      }
    });
    document.body.addEventListener("mouseout", function(event2) {
      if (!event2.target.closest("#geogebra-calculator canvas")) return;
      document.body.style.overflow = "scroll";
      document.documentElement.style.marginRight = "0";
      const container = document.getElementById("calculator-container");
      if (container) {
        container.style.right = calcOffsetR + "px";
        container.style.bottom = calcOffsetB + "px";
      }
    });
    document.body.addEventListener("click", function(event2) {
      const toggle = event2.target.closest("#calculator-toggle");
      if (!toggle) return;
      const container = document.getElementById("calculator-container");
      if (!container) return;
      if (container.style.display === "none" || !container.style.display) {
        container.style.display = "block";
        toggle.classList.add("open");
        toggle.setAttribute("title", "Hide calculator");
        toggle.setAttribute("aria-expanded", "true");
        const existingScript = document.getElementById("create_ggb_calc");
        if (!existingScript) {
          const ggbScript = document.createElement("script");
          ggbScript.id = "create_ggb_calc";
          ggbScript.innerHTML = "ggbApp.inject('geogebra-calculator')";
          document.body.appendChild(ggbScript);
        } else {
          calculatorOnload();
        }
      } else {
        container.style.display = "none";
        toggle.classList.remove("open");
        toggle.setAttribute("title", "Show calculator");
        toggle.setAttribute("aria-expanded", "false");
      }
    });
  }

  // ../../js/src/keyboard-nav.js
  var justHitEscape = false;
  function processWorkspace() {
    if (typeof MathJax !== "undefined" && MathJax.typesetPromise) {
      MathJax.typesetPromise();
    }
  }
  function initKeyboardNav() {
    document.onkeyup = function(event2) {
      const e = event2 || window.event;
      switch (e.keyCode) {
        case 13:
          justHitEscape = false;
          if (document.activeElement.classList.contains("workspace")) {
            processWorkspace();
          }
          break;
        // Fixed: was missing, caused fallthrough to ESC handler
        case 27: {
          const parentSageCell = document.activeElement.closest(".sagecell_editor");
          if (parentSageCell && !justHitEscape) {
            justHitEscape = true;
            setTimeout(function() {
              justHitEscape = false;
            }, 1e3);
          } else if (typeof knowl_focus_stack !== "undefined" && knowl_focus_stack.length > 0) {
            const mostRecentlyOpened = knowl_focus_stack.pop();
            if (typeof knowl_focus_stack_uid !== "undefined") {
              knowl_focus_stack_uid.pop();
            }
            mostRecentlyOpened.focus();
          } else {
            break;
          }
          break;
        }
      }
    };
  }
  function initAnchorKnowl() {
    if (!window.location.hash.length) return;
    const id = window.location.hash.substring(1);
    const anchor = document.getElementById(id);
    if (!anchor) return;
    if (anchor.tagName === "ARTICLE") {
      const containedKnowl = anchor.querySelector("a[data-knowl]");
      if (containedKnowl && containedKnowl.parentElement === anchor) {
        containedKnowl.click();
      }
    } else if (anchor.hasAttribute("data-knowl")) {
      anchor.click();
    } else {
      const hiddenContent = anchor.closest(".hidden-content");
      if (hiddenContent) {
        const refId = hiddenContent.id;
        const knowl = document.querySelector(
          '[data-refid="' + refId + '"]'
        );
        if (knowl) knowl.click();
      }
    }
  }

  // ../../js/src/print-preview/geometry.js
  function toPixels(value) {
    if (typeof value === "number") return value;
    if (typeof value !== "string") return 0;
    value = value.trim();
    if (value.endsWith("px")) {
      return parseFloat(value);
    } else if (value.endsWith("in")) {
      return Math.floor(parseFloat(value) * 96);
    } else if (value.endsWith("cm")) {
      return Math.floor(parseFloat(value) * 37.8);
    } else if (value.endsWith("mm")) {
      return Math.floor(parseFloat(value) * 3.78);
    } else if (value.endsWith("pt")) {
      return Math.floor(parseFloat(value) * (96 / 72));
    } else {
      return parseFloat(value) || 0;
    }
  }
  function getElementTotalHeight(elem) {
    const style = getComputedStyle(elem);
    const marginTop = parseFloat(style.marginTop);
    const marginBottom = parseFloat(style.marginBottom);
    const height = elem.offsetHeight;
    return height + marginTop + marginBottom;
  }
  function getElemWorkspaceHeight(elem) {
    if (elem.classList.contains("sidebyside")) {
      const sbspanels = elem.querySelectorAll(".sbspanel");
      let max = 0;
      sbspanels.forEach((panel) => {
        const workspaces2 = panel.querySelectorAll(".workspace");
        let totalHeight2 = 0;
        workspaces2.forEach((workspace) => {
          const workspaceHeight = workspace.offsetHeight;
          if (workspaceHeight) {
            totalHeight2 += workspaceHeight;
          }
        });
        if (totalHeight2 > max) {
          max = totalHeight2;
        }
      });
      return max;
    }
    let columns = 1;
    if (elem.classList.contains("exercisegroup")) {
      for (let i = 2; i <= 6; i++) {
        if (elem.querySelector(`.cols${i}`)) {
          columns = i;
          break;
        }
      }
    }
    const workspaces = elem.querySelectorAll(".workspace");
    let totalHeight = 0;
    workspaces.forEach((ws) => {
      const workspaceHeight = ws.offsetHeight;
      if (workspaceHeight) {
        totalHeight += workspaceHeight;
      }
    });
    return totalHeight / columns;
  }
  function setPageGeometryCSS({ paperSize, margins }) {
    const existingStyle = document.getElementById("page-geometry-css");
    if (existingStyle) {
      existingStyle.remove();
    }
    const wsWidth = paperSize === "letter" ? "816px" : "794px";
    const wsHeight = paperSize === "letter" ? "1056px" : "1123px";
    const style = document.createElement("style");
    style.id = "page-geometry-css";
    style.textContent = `
        :root {
            --ws-width: ${wsWidth};
            --ws-height: ${wsHeight};
            --ws-top-margin: ${margins.top}px;
            --ws-right-margin: ${margins.right}px;
            --ws-bottom-margin: ${margins.bottom}px;
            --ws-left-margin: ${margins.left}px;
        }
        @page {
            margin: var(--ws-top-margin, ${margins.top}px) var(--ws-right-margin, ${margins.right}px) var(--ws-bottom-margin, ${margins.bottom}px) var(--ws-left-margin, ${margins.left}px);
        }
    `;
    document.head.appendChild(style);
  }

  // ../../js/src/print-preview/workspace.js
  function setInitialWorkspaceHeights() {
    const workspaces = document.querySelectorAll(".workspace");
    workspaces.forEach((ws) => {
      ws.style.height = ws.getAttribute("data-space") || "0px";
      ws.setAttribute("contenteditable", "true");
    });
  }
  function adjustWorkspaceToFitPage({ paperSize, margins }) {
    const highlightCheckbox = document.getElementById(
      "highlight-workspace-checkbox"
    );
    const wasHighlighted = highlightCheckbox && highlightCheckbox.checked;
    if (wasHighlighted) {
      toggleWorkspaceHighlight(false);
    }
    let paperWidth, paperHeight;
    if (paperSize === "a4" || document.body.classList.contains("a4")) {
      paperWidth = 794;
      paperHeight = 1122.5;
    } else {
      paperWidth = 816;
      paperHeight = 1056;
    }
    const paperContentHeight = paperHeight - (margins.top + margins.bottom);
    setInitialWorkspaceHeights();
    const pages = document.querySelectorAll(".onepage");
    pages.forEach((page) => {
      page.style.width = paperWidth + "px";
      const rows = page.children;
      let totalContentHeight = 0;
      let totalWorkspaceHeight = 0;
      for (const row of rows) {
        totalContentHeight += getElementTotalHeight(row);
        totalWorkspaceHeight += getElemWorkspaceHeight(row);
      }
      if (totalWorkspaceHeight === 0) {
        page.style.width = "";
        return;
      }
      const extraHeight = paperContentHeight - totalContentHeight;
      const workspaceAdjustmentFactor = (totalWorkspaceHeight + extraHeight) / totalWorkspaceHeight;
      const pageWorkspaces = page.querySelectorAll(".workspace");
      pageWorkspaces.forEach((ws) => {
        const originalHeight = ws.offsetHeight;
        const newHeight = originalHeight * workspaceAdjustmentFactor;
        ws.style.height = newHeight + "px";
      });
      page.style.width = "";
    });
    if (wasHighlighted) {
      toggleWorkspaceHighlight(true);
    }
  }
  function toggleWorkspaceHighlight(isChecked) {
    if (isChecked) {
      document.body.classList.add("highlight-workspace");
      if (!document.querySelector(".workspace-container")) {
        document.querySelectorAll(".workspace").forEach((workspace) => {
          const container = document.createElement("div");
          container.classList.add("workspace-container");
          container.style.height = window.getComputedStyle(workspace).height;
          const original = document.createElement("div");
          original.classList.add("original-workspace");
          const originalHeight = workspace.getAttribute("data-space") || "0px";
          original.setAttribute(
            "title",
            "Author-specified workspace height (" + originalHeight + ")"
          );
          original.style.height = originalHeight;
          container.appendChild(original);
          if (original.offsetHeight > workspace.offsetHeight) {
            original.classList.add("warning");
          }
          workspace.parentNode.insertBefore(container, workspace);
          container.appendChild(workspace);
        });
      }
    } else {
      document.body.classList.remove("highlight-workspace");
      document.querySelectorAll(".workspace-container").forEach((container) => {
        const workspace = container.querySelector(".workspace");
        container.parentNode.insertBefore(workspace, container);
        container.remove();
      });
    }
  }

  // ../../js/src/print-preview/page-breaks.js
  function findPageBreaks(rows, pageHeight) {
    let pageBreaks = [];
    let minCost = Array(rows.length + 1).fill(Infinity);
    minCost[rows.length] = 0;
    let nextPageBreak = Array(rows.length).fill(-1);
    for (let i = rows.length - 1; i >= 0; i--) {
      let cumulativeHeight = 0;
      for (let j = i; j < rows.length; j++) {
        cumulativeHeight += rows[j].height;
        if (cumulativeHeight > pageHeight) {
          if (j === i) {
            minCost[i] = 0;
            nextPageBreak[i] = i + 1;
          }
          break;
        }
        const cost = (pageHeight - cumulativeHeight) ** 2 + minCost[j + 1];
        if (cost < minCost[i]) {
          minCost[i] = cost;
          nextPageBreak[i] = j + 1;
        }
      }
    }
    let nextPage = 1;
    while (nextPage < rows.length) {
      pageBreaks.push(nextPageBreak[nextPage]);
      nextPage = nextPageBreak[nextPage];
    }
    return pageBreaks;
  }

  // ../../js/src/print-preview/pages.js
  function flattenParagraphsSections(printout) {
    const paragraphsSections = printout.querySelectorAll(
      "section.paragraphs"
    );
    paragraphsSections.forEach((section) => {
      const parent = section.parentNode;
      while (section.firstChild) {
        parent.insertBefore(section.firstChild, section);
      }
      parent.removeChild(section);
    });
  }
  function waitForImages(container, timeoutMs = 5e3) {
    const images = container.querySelectorAll("img");
    const promises = [];
    for (const img of images) {
      if (!img.complete) {
        promises.push(
          new Promise((resolve) => {
            img.addEventListener("load", resolve, { once: true });
            img.addEventListener("error", resolve, { once: true });
          })
        );
      }
    }
    if (promises.length === 0) return Promise.resolve();
    return Promise.race([
      Promise.all(promises),
      new Promise((resolve) => setTimeout(resolve, timeoutMs))
    ]);
  }
  function adjustPrintoutPages() {
    const printout = document.querySelector(
      "section.worksheet, section.handout"
    );
    if (!printout) return;
    const pages = printout.querySelectorAll(".onepage");
    if (pages.length === 0) return;
    const firstPage = pages[0];
    const lastPage = pages[pages.length - 1];
    const pageFirstChild = firstPage.firstChild;
    let currentChild = printout.firstChild;
    while (currentChild && currentChild !== firstPage) {
      const nextChild2 = currentChild.nextSibling;
      firstPage.insertBefore(currentChild, pageFirstChild);
      currentChild = nextChild2;
    }
    let nextChild = lastPage.nextSibling;
    while (nextChild) {
      const tempChild = nextChild;
      nextChild = nextChild.nextSibling;
      lastPage.appendChild(tempChild);
    }
  }
  function createPrintoutPages(margins) {
    const conservativeContentHeight = 1056 - (margins.top + margins.bottom);
    const conservativeContentWidth = 794 - (margins.left + margins.right);
    const printout = document.querySelector(
      "section.worksheet, section.handout"
    );
    if (!printout) return;
    printout.style.width = (conservativeContentWidth + margins.left + margins.right).toString() + "px";
    setInitialWorkspaceHeights(printout);
    let rows = [];
    for (const child of printout.children) {
      if (child.classList.contains("sidebyside")) {
        rows.push(child);
      } else if (child.querySelector(".task")) {
        rows.push(child);
        const tasks = child.querySelectorAll(".task, .conclusion");
        for (let i = 0; i < tasks.length; i++) {
          let parent = tasks[i].parentElement;
          let grandparent = parent.parentElement;
          if (grandparent.classList.contains("task")) {
            tasks[i].classList.add("subsubtask");
          } else if (parent.classList.contains("task")) {
            tasks[i].classList.add("subtask");
          }
        }
        for (let i = tasks.length - 1; i > 0; i--) {
          printout.insertBefore(tasks[i], child.nextSibling);
        }
      } else {
        rows.push(child);
      }
    }
    let blockList = [];
    for (const row of rows) {
      let blockHeight = getElementTotalHeight(row);
      if (blockHeight === 0) continue;
      let totalWorkspaceHeight = 0;
      if (row.querySelector(".workspace")) {
        totalWorkspaceHeight = getElemWorkspaceHeight(row);
      }
      blockList.push({
        elem: row,
        height: blockHeight,
        workspaceHeight: totalWorkspaceHeight
      });
    }
    const pageBreaks = findPageBreaks(blockList, conservativeContentHeight);
    for (let i = 0; i < pageBreaks.length; i++) {
      const pageDiv = document.createElement("section");
      pageDiv.classList.add("onepage");
      if (i === 0) pageDiv.classList.add("firstpage");
      if (i === pageBreaks.length - 1) pageDiv.classList.add("lastpage");
      const start = pageBreaks[i - 1] || 0;
      const end = pageBreaks[i];
      for (let j = start; j < end; j++) {
        pageDiv.appendChild(blockList[j].elem);
      }
      printout.appendChild(pageDiv);
    }
    for (const child of Array.from(printout.children)) {
      if (!child.classList.contains("onepage")) {
        printout.removeChild(child);
      }
    }
  }

  // ../../js/src/print-preview/headers-footers.js
  function addHeadersAndFootersToPrintout() {
    const printout = document.querySelector(
      "section.worksheet, section.handout"
    );
    if (!printout) return;
    const pages = printout.querySelectorAll(".onepage");
    pages.forEach((page, index) => {
      const isFirstPage = index === 0;
      const headerDiv = document.createElement("div");
      headerDiv.classList.add(
        isFirstPage ? "first-page-header" : "running-header",
        "hidden"
      );
      headerDiv.innerHTML = `<div class="header-left" contenteditable="true"></div><div class="header-center" contenteditable="true"></div><div class="header-right" contenteditable="true"></div>`;
      page.insertBefore(headerDiv, page.firstChild);
      const footerDiv = document.createElement("div");
      footerDiv.classList.add(
        isFirstPage ? "first-page-footer" : "running-footer",
        "hidden"
      );
      footerDiv.innerHTML = `<div class="footer-left" contenteditable="true"></div><div class="footer-center" contenteditable="true"></div><div class="footer-right" contenteditable="true"></div>`;
      page.appendChild(footerDiv);
    });
    const keys = [
      "header-first-left",
      "header-first-center",
      "header-first-right",
      "footer-first-left",
      "footer-first-center",
      "footer-first-right",
      "header-running-left",
      "header-running-center",
      "header-running-right",
      "footer-running-left",
      "footer-running-center",
      "footer-running-right"
    ];
    const content2 = {};
    keys.forEach((key) => {
      content2[key] = localStorage.getItem(key) || printout.getAttribute(`data-${key}`) || "";
    });
    const firstHeader = document.querySelector(".first-page-header");
    if (firstHeader) {
      firstHeader.querySelector(".header-left").innerHTML = content2["header-first-left"];
      firstHeader.querySelector(".header-center").innerHTML = content2["header-first-center"];
      firstHeader.querySelector(".header-right").innerHTML = content2["header-first-right"];
    }
    const firstFooter = document.querySelector(".first-page-footer");
    if (firstFooter) {
      firstFooter.querySelector(".footer-left").innerHTML = content2["footer-first-left"];
      firstFooter.querySelector(".footer-center").innerHTML = content2["footer-first-center"];
      firstFooter.querySelector(".footer-right").innerHTML = content2["footer-first-right"];
    }
    document.querySelectorAll(".running-header").forEach((headerDiv) => {
      headerDiv.querySelector(".header-left").innerHTML = content2["header-running-left"];
      headerDiv.querySelector(".header-center").innerHTML = content2["header-running-center"];
      headerDiv.querySelector(".header-right").innerHTML = content2["header-running-right"];
    });
    document.querySelectorAll(".running-footer").forEach((footerDiv) => {
      footerDiv.querySelector(".footer-left").innerHTML = content2["footer-running-left"];
      footerDiv.querySelector(".footer-center").innerHTML = content2["footer-running-center"];
      footerDiv.querySelector(".footer-right").innerHTML = content2["footer-running-right"];
    });
    const selectorMap = {
      "header-first-left": ".first-page-header .header-left",
      "header-first-center": ".first-page-header .header-center",
      "header-first-right": ".first-page-header .header-right",
      "footer-first-left": ".first-page-footer .footer-left",
      "footer-first-center": ".first-page-footer .footer-center",
      "footer-first-right": ".first-page-footer .footer-right",
      "header-running-left": ".running-header .header-left",
      "header-running-center": ".running-header .header-center",
      "header-running-right": ".running-header .header-right",
      "footer-running-left": ".running-footer .footer-left",
      "footer-running-center": ".running-footer .footer-center",
      "footer-running-right": ".running-footer .footer-right"
    };
    keys.forEach((key) => {
      const elements = document.querySelectorAll(selectorMap[key]);
      elements.forEach((elem) => {
        elem.addEventListener("input", () => {
          localStorage.setItem(key, elem.innerHTML);
        });
      });
    });
  }

  // ../../js/src/print-preview/paper-size.js
  function getPaperSize() {
    let paperSize = localStorage.getItem("papersize");
    if (paperSize) return paperSize;
    try {
      fetch("https://ipapi.co/json/").then((response) => response.json()).then((data) => {
        const continent = data && data.continent_code ? data.continent_code : "";
        paperSize = continent === "NA" || continent === "SA" ? "letter" : "a4";
        const radio = document.querySelector(
          `input[name="papersize"][value="${paperSize}"]`
        );
        if (radio) {
          radio.checked = true;
          localStorage.setItem("papersize", paperSize);
        }
        document.body.classList.remove("a4", "letter");
        document.body.classList.add(paperSize);
      }).catch((err) => {
        throw err;
      });
    } catch (e) {
      const radio = document.querySelector(
        'input[name="papersize"][value="letter"]'
      );
      if (radio) radio.checked = true;
    }
    return paperSize || "letter";
  }

  // ../../js/src/print-preview/section-swap.js
  async function loadPrintout(printableSectionID) {
    const themeStylesheetLink = document.querySelector(
      'link[rel="stylesheet"][href*="theme"]'
    );
    const themeStylesheetHref = themeStylesheetLink ? themeStylesheetLink.getAttribute("href") : null;
    if (themeStylesheetHref) {
      const printStylesheetHref = themeStylesheetHref.replace(
        /theme.*\.css/,
        "print-worksheet.css"
      );
      themeStylesheetLink.setAttribute("href", printStylesheetHref);
      await new Promise((resolve) => {
        themeStylesheetLink.addEventListener("load", resolve, {
          once: true
        });
      });
    }
    const printableSection = document.getElementById(printableSectionID);
    if (!printableSection) {
      console.error("No section found with ID:", printableSectionID);
      return;
    }
    const ptxContent = document.querySelector(".ptx-content");
    const existingSections = ptxContent.querySelectorAll(":scope > section");
    existingSections.forEach((sec) => ptxContent.removeChild(sec));
    ptxContent.appendChild(printableSection);
  }

  // ../../js/src/print-preview/solutions.js
  function rewriteSolutions() {
    const bornHiddenKnowls = document.querySelectorAll(
      ".worksheet details, .handout details"
    );
    bornHiddenKnowls.forEach(function(detail) {
      const summary = detail.querySelector("summary");
      const content2 = detail.innerHTML.replace(summary.outerHTML, "");
      const div = document.createElement("div");
      div.classList = detail.classList;
      if (summary) {
        const title = document.createElement("h5");
        title.innerHTML = summary.innerHTML;
        div.appendChild(title);
      }
      const body = document.createElement("div");
      body.innerHTML = content2;
      div.appendChild(body);
      detail.parentNode.replaceChild(div, detail);
    });
  }

  // ../../js/src/print-preview/index.js
  async function initPrintPreview() {
    const urlParams = new URLSearchParams(window.location.search);
    if (!urlParams.has("printpreview")) return;
    const printableSectionID = urlParams.get("printpreview");
    await loadPrintout(printableSectionID);
    const marginList = document.querySelector("section.worksheet, section.handout").getAttribute("data-margins").split(" ");
    const margins = {
      top: toPixels(marginList[0] || "0.75in"),
      right: toPixels(marginList[1] || "0.75in"),
      bottom: toPixels(marginList[2] || "0.75in"),
      left: toPixels(marginList[3] || "0.75in")
    };
    rewriteSolutions();
    let paperSize = getPaperSize();
    if (paperSize) {
      const radio = document.querySelector(
        `input[name="papersize"][value="${paperSize}"]`
      );
      if (radio) radio.checked = true;
      document.body.classList.remove("a4", "letter");
      document.body.classList.add(paperSize);
      setPageGeometryCSS({ paperSize, margins });
    }
    const papersizeRadios = document.querySelectorAll(
      'input[name="papersize"]'
    );
    papersizeRadios.forEach((radio) => {
      radio.addEventListener("change", function() {
        if (this.checked) {
          document.body.classList.remove("a4", "letter");
          document.body.classList.add(this.value);
          localStorage.setItem("papersize", this.value);
          setPageGeometryCSS({ paperSize: this.value, margins });
          adjustWorkspaceToFitPage({
            paperSize: this.value,
            margins
          });
        }
      });
    });
    for (const solutionType of ["hint", "answer", "solution"]) {
      const checkbox = document.getElementById(
        `hide-${solutionType}-checkbox`
      );
      if (!checkbox) continue;
      const storageKey = `hide-${solutionType}`;
      if ((solutionType === "answer" || solutionType === "solution") && !localStorage.getItem(storageKey)) {
        checkbox.checked = true;
        localStorage.setItem(storageKey, "true");
      }
      checkbox.checked = localStorage.getItem(storageKey) === "true";
      document.querySelectorAll(`div.${solutionType}`).forEach((elem) => {
        if (checkbox.checked) {
          elem.classList.add("hidden");
        } else {
          elem.classList.remove("hidden");
        }
      });
      checkbox.addEventListener("change", function() {
        localStorage.setItem(storageKey, this.checked);
        document.querySelectorAll(`div.${solutionType}`).forEach((elem) => {
          if (checkbox.checked) {
            elem.classList.add("hidden");
          } else {
            elem.classList.remove("hidden");
          }
          adjustWorkspaceToFitPage({ paperSize, margins });
        });
      });
    }
    const printoutSection = document.querySelector(
      "section.worksheet, section.handout"
    );
    if (printoutSection) {
      flattenParagraphsSections(printoutSection);
      await waitForImages(printoutSection);
    }
    if (document.querySelector(".onepage")) {
      adjustPrintoutPages();
    } else {
      createPrintoutPages(margins);
    }
    addHeadersAndFootersToPrintout();
    for (const hf of [
      "first-page-header",
      "running-header",
      "first-page-footer",
      "running-footer"
    ]) {
      const checkbox = document.getElementById(`print-${hf}-checkbox`);
      if (!checkbox) continue;
      checkbox.checked = localStorage.getItem(`print-${hf}`) === "true";
      document.querySelectorAll(`.${hf}`).forEach((elem) => {
        if (checkbox.checked) {
          elem.classList.remove("hidden");
        } else {
          elem.classList.add("hidden");
        }
      });
      checkbox.addEventListener("change", function() {
        localStorage.setItem(`print-${hf}`, this.checked);
        document.querySelectorAll(`.${hf}`).forEach((elem) => {
          if (checkbox.checked) {
            elem.classList.remove("hidden");
          } else {
            elem.classList.add("hidden");
          }
          adjustWorkspaceToFitPage({ paperSize, margins });
        });
      });
    }
    adjustWorkspaceToFitPage({ paperSize, margins });
    const highlightCheckbox = document.getElementById(
      "highlight-workspace-checkbox"
    );
    if (highlightCheckbox) {
      highlightCheckbox.checked = localStorage.getItem("highlightWorkspace") === "true";
      highlightCheckbox.addEventListener("change", function() {
        localStorage.setItem("highlightWorkspace", this.checked);
        toggleWorkspaceHighlight(this.checked);
      });
      toggleWorkspaceHighlight(highlightCheckbox.checked);
    }
  }

  // ../../js/src/theme.js
  function isDarkMode() {
    if (document.documentElement.dataset.darkmode === "disabled") return false;
    const currentTheme = localStorage.getItem("theme");
    if (currentTheme === "dark") return true;
    if (currentTheme === "light") return false;
    return window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches;
  }
  function setDarkMode(isDark) {
    if (document.documentElement.dataset.darkmode === "disabled") return;
    const parentHtml = document.documentElement;
    const iframes = document.querySelectorAll(
      "iframe[data-dark-mode-enabled]"
    );
    if (isDark) {
      parentHtml.classList.add("dark-mode");
    } else {
      parentHtml.classList.remove("dark-mode");
    }
    for (const iframe of iframes) {
      try {
        const iframeHtml = iframe.contentWindow.document.documentElement;
        if (isDark) {
          iframeHtml.classList.add("dark-mode");
        } else {
          iframeHtml.classList.remove("dark-mode");
        }
      } catch (err) {
        console.warn("Dark mode sync to iframe failed:", err);
      }
    }
    const modeButton = document.getElementById("light-dark-button");
    if (modeButton) {
      modeButton.querySelector(".icon").innerText = isDark ? "light_mode" : "dark_mode";
      modeButton.querySelector(".name").innerText = isDark ? "Light Mode" : "Dark Mode";
    }
  }
  function initThemeToggle() {
    setDarkMode(isDarkMode());
    const isDark = isDarkMode();
    setDarkMode(isDark);
    const modeButton = document.getElementById("light-dark-button");
    if (modeButton) {
      modeButton.addEventListener("click", function() {
        const wasDark = isDarkMode();
        setDarkMode(!wasDark);
        localStorage.setItem("theme", wasDark ? "light" : "dark");
      });
    }
  }

  // ../../js/src/embed.js
  function initShareButton() {
    const shareButton = document.getElementById("embed-button");
    if (!shareButton) return;
    const sharePopup = document.getElementById("embed-popup");
    const embedCode = "<iframe src='" + window.location.href + "?embed' width='100%' height='1000px' frameborder='0'></iframe>";
    const embedTextbox = document.getElementById("embed-code-textbox");
    if (embedTextbox) {
      embedTextbox.value = embedCode;
    }
    shareButton.addEventListener("click", function() {
      sharePopup.classList.toggle("hidden");
    });
    const copyButton = document.getElementById("copy-embed-button");
    if (copyButton) {
      copyButton.addEventListener("click", function() {
        const textbox = document.getElementById("embed-code-textbox");
        if (textbox) {
          navigator.clipboard.writeText(embedCode).then(() => {
            console.log("Embed code copied to clipboard!");
          }).catch((err) => {
            console.error("Failed to copy embed code: ", err);
          });
          copyButton.querySelector(".icon").innerText = "library_add_check";
          setTimeout(function() {
            copyButton.querySelector(".icon").innerText = "content_copy";
            sharePopup.classList.add("hidden");
          }, 450);
        }
      });
    }
  }
  function initEmbedMode() {
    const urlParams = new URLSearchParams(window.location.search);
    if (!urlParams.has("embed")) return;
    if (urlParams.get("embed") === "dark") {
      setDarkMode(true);
    } else {
      setDarkMode(false);
    }
    const elemsToHide = [
      "ptx-navbar",
      "ptx-masthead",
      "ptx-page-footer",
      "ptx-sidebar",
      "ptx-content-footer"
    ];
    for (const id of elemsToHide) {
      const elem = document.getElementById(id);
      if (elem) {
        elem.classList.add("hidden");
      }
    }
  }

  // ../../js/src/code-copy.js
  function initCodeCopyButtons() {
    const elements = document.querySelectorAll(".clipboardable");
    for (const el of elements) {
      const div = document.createElement("div");
      div.classList.add("clipboardable");
      el.classList.remove("clipboardable");
      el.replaceWith(div);
      div.insertAdjacentElement("afterbegin", el);
      div.insertAdjacentHTML(
        "beforeend",
        `
    <button class="code-copy" title="Copy code" role="button" aria-label="Copy code" >
        <span class="copyicon material-symbols-outlined">content_copy</span>
        <span class="checkmark material-symbols-outlined">check</span>
    </button>
            `.trim()
      );
    }
  }
  function initCodeCopyHandler() {
    document.addEventListener("click", (ev) => {
      const codeBox = ev.target.closest(".clipboardable");
      if (!navigator.clipboard || !codeBox) return;
      const button = ev.target.closest(".code-copy");
      if (!button) return;
      const preContent = codeBox.querySelector("pre").textContent;
      navigator.clipboard.writeText(preContent);
      button.classList.toggle("copied");
      setTimeout(() => button.classList.toggle("copied"), 1e3);
    });
  }

  // ../../js/src/deprecated/auto-id.js
  function initAutoId() {
    const noIdParagraphs = document.querySelectorAll(".main p:not([id])");
    for (let n = noIdParagraphs.length - 1; n >= 0; --n) {
      const e = noIdParagraphs[n];
      if (e.hasAttribute("id")) continue;
      if (e.classList.contains("watermark")) continue;
      const prevParagraphs = [];
      let sibling = e.previousElementSibling;
      while (sibling) {
        if (sibling.tagName === "P") {
          prevParagraphs.push(sibling);
        }
        sibling = sibling.previousElementSibling;
      }
      if (prevParagraphs.length === 0) continue;
      let partsFound = 1;
      const partsToId = [e];
      for (let i = 0; i < prevParagraphs.length; ++i) {
        const thisPrevious = prevParagraphs[i];
        if (!thisPrevious.hasAttribute("id")) {
          partsToId.unshift(thisPrevious);
        } else {
          const baseId = thisPrevious.id;
          for (let j = 0; j < partsToId.length; ++j) {
            ++partsFound;
            const nextId = baseId + "-part" + partsFound.toString();
            partsToId[j].setAttribute("id", nextId);
          }
          break;
        }
      }
    }
  }

  // ../../js/src/deprecated/video-magnify.js
  function initVideoMagnify() {
    const allIframes = document.querySelectorAll("body iframeXXXX");
    for (let i = 0; i < allIframes.length; i++) {
      const thisItem = allIframes[i];
      const thisItemSrc = thisItem.src;
      if (!thisItemSrc.includes("youtube")) continue;
      const thisItemId = thisItem.id;
      const thisItemWidth = thisItem.width;
      const thisItemHeight = thisItem.height;
      if (thisItemHeight < 150) continue;
      const emptyDiv = document.createElement("div");
      const videomagContainer = document.createElement("div");
      const parentTag = thisItem.parentElement.tagName;
      if (parentTag === "FIGURE") {
        videomagContainer.setAttribute("class", "videobig");
      } else {
        videomagContainer.setAttribute("class", "videobig nofigure");
      }
      videomagContainer.setAttribute("video-id", thisItemId);
      videomagContainer.setAttribute("data-width", thisItemWidth);
      videomagContainer.setAttribute("data-height", thisItemHeight);
      videomagContainer.innerHTML = "fit width";
      thisItem.insertAdjacentElement("beforebegin", emptyDiv);
      thisItem.insertAdjacentElement("beforebegin", videomagContainer);
      thisItem.insertAdjacentElement("beforebegin", emptyDiv);
    }
    document.body.addEventListener("click", function(event2) {
      const bigBtn = event2.target.closest(".videobig");
      if (bigBtn) {
        const videoId = bigBtn.getAttribute("video-id");
        const video = document.getElementById(videoId);
        const originalWidth = parseInt(bigBtn.getAttribute("data-width"));
        const originalHeight = parseInt(bigBtn.getAttribute("data-height"));
        const browserWidth = window.innerWidth;
        const widthRatio = browserWidth / originalWidth;
        video.setAttribute("width", widthRatio * originalWidth);
        video.setAttribute("height", widthRatio * originalHeight);
        video.setAttribute(
          "style",
          "position:relative; left:-260px; z-index:1000"
        );
        bigBtn.setAttribute("class", "videosmall");
        bigBtn.innerHTML = "make small";
        return;
      }
      const smallBtn = event2.target.closest(".videosmall");
      if (smallBtn) {
        const videoId = smallBtn.getAttribute("video-id");
        const video = document.getElementById(videoId);
        const originalWidth = smallBtn.getAttribute("data-width");
        const originalHeight = smallBtn.getAttribute("data-height");
        video.removeAttribute("style");
        video.setAttribute("width", originalWidth);
        video.setAttribute("height", originalHeight);
        smallBtn.setAttribute("class", "videobig");
        smallBtn.innerHTML = "fit width";
      }
    });
  }

  // ../../js/src/pretext-core-entry.js
  setDarkMode(isDarkMode());
  window.isDarkMode = isDarkMode;
  window.setDarkMode = setDarkMode;
  window.addEventListener("DOMContentLoaded", function() {
    initToc();
    initFocusedToc();
    initScrollToc();
    initPermalinks();
    initThemeToggle();
    initShareButton();
    initEmbedMode();
    initCodeCopyButtons();
    initPrintPreview();
  });
  window.addEventListener("load", function() {
    initKnowls();
    initLtiIframeResizer();
    initImageMagnify();
    initGeoGebra();
    initKeyboardNav();
    initAnchorKnowl();
    initAutoId();
    initVideoMagnify();
  });
  initCodeCopyHandler();
})();
//# sourceMappingURL=pretext-core.js.map
