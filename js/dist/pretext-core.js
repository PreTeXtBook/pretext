(() => {
  var __create = Object.create;
  var __defProp = Object.defineProperty;
  var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
  var __getOwnPropNames = Object.getOwnPropertyNames;
  var __getProtoOf = Object.getPrototypeOf;
  var __hasOwnProp = Object.prototype.hasOwnProperty;
  var __commonJS = (cb, mod) => function __require() {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  };
  var __copyProps = (to, from, except, desc) => {
    if (from && typeof from === "object" || typeof from === "function") {
      for (let key of __getOwnPropNames(from))
        if (!__hasOwnProp.call(to, key) && key !== except)
          __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
    }
    return to;
  };
  var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
    // If the importer is in node compatibility mode or this is not an ESM
    // file that has been converted to a CommonJS file using a Babel-
    // compatible transform (i.e. "__esModule" has not been set), then set
    // "default" to the CommonJS "module.exports" for node compatibility.
    isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
    mod
  ));

  // ../../js/knowl.js
  var require_knowl = __commonJS({
    "../../js/knowl.js"(exports, module) {
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
      var SlideRevealer = class _SlideRevealer {
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
          this.animationState = _SlideRevealer.STATE.INACTIVE;
          this.animatedElementInlineStyle = null;
          this.triggerElement.addEventListener("click", (e2) => this.onClick(e2));
        }
        isBusy() {
          return this.animationState !== _SlideRevealer.STATE.INACTIVE || this.animatedElementInlineStyle !== null;
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
        onClick(e2) {
          if (e2) e2.preventDefault();
          if (this.isBusy()) return;
          this.storeAnimatedElementInlineStyle();
          this.animatedElement.style.overflow = "hidden";
          if (this.animationState === _SlideRevealer.STATE.CLOSING || !this.animatedElement.hasAttribute("open")) {
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
          } else if (this.animationState === _SlideRevealer.STATE.EXPANDING || this.animatedElement.hasAttribute("open")) {
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
          this.animationState = expanding ? _SlideRevealer.STATE.EXPANDING : _SlideRevealer.STATE.CLOSING;
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
            this.animationState = _SlideRevealer.STATE.INACTIVE;
            this.restoreAnimatedElementInlineStyle();
          };
        }
        onAnimationFinish(isOpen) {
          this.animation = null;
          this.animationState = _SlideRevealer.STATE.INACTIVE;
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
            hasCallback.forEach((el2) => {
              window[el2.getAttribute("data-knowl-callback")](el2, open);
            });
          }
        }
      };
      var LinkKnowl = class _LinkKnowl {
        // Used to uniquely identify XrefKnowls
        static xrefCount = 0;
        // Factory to create an XrefKnowl from a knowl link
        // Will avoid duplicate initialization
        // This should be used by outside code to create XrefKnowls
        static initializeXrefKnowl(knowlLinkElement) {
          if (knowlLinkElement.getAttribute("data-knowl-uid") === null) {
            return new _LinkKnowl(knowlLinkElement);
          }
        }
        // "Private" constructor - should only be called by initializeXrefKnowl
        constructor(knowlLinkElement) {
          this.linkElement = knowlLinkElement;
          this.outputElement = null;
          this.slideHandler = null;
          this.uid = _LinkKnowl.xrefCount++;
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
          let el2 = this.linkElement.parentElement;
          let problemAncestor = el2.closest(invalidParents);
          while (problemAncestor && problemAncestor !== el2) {
            el2 = problemAncestor;
            problemAncestor = el2.closest(invalidParents);
          }
          return el2;
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
              [...runestoneElements].forEach((e2) => {
                const rsId = e2.querySelector("[data-component]")?.id;
                const onPage = document.getElementById(rsId);
                if (onPage) {
                  e2.innerHTML = `<div class="para">The interactive that belongs here is already on the page and cannot appear multiple times. <a href="#${rsId}">Scroll to interactive.</a>`;
                } else {
                  window.runestoneComponents.renderOneComponent(e2);
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
      };
    }
  });

  // ../../js/pretext.js
  function getOffsetTop(e2) {
    if (!e2) return 0;
    return getOffsetTop(e2.offsetParent) + e2.offsetTop;
  }
  function scrollTocToActive() {
    let fileNameWHash = window.location.href.split("/").pop();
    let fileName = fileNameWHash.split("#")[0];
    let tocEntry = document.querySelector('#ptx-toc a[href="' + fileName + '"]');
    if (!tocEntry) {
      return;
    }
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
    thesidebar = document.getElementById("ptx-sidebar");
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
    } catch (e2) {
      return false;
    }
  }
  window.addEventListener("DOMContentLoaded", function(event2) {
    thetocbutton = document.getElementsByClassName("toc-toggle")[0];
    thetocbutton.addEventListener("click", (e2) => {
      toggletoc();
      e2.stopPropagation();
    });
    if (getComputedStyle(document.documentElement).getPropertyValue("--auto-collapse-toc") == "yes") {
      const sidebar = document.getElementById("ptx-sidebar");
      window.addEventListener("click", function(event3) {
        if (sidebar.classList.contains("visible")) {
          if (!event3.composedPath().includes(sidebar)) {
            toggletoc();
          }
        }
      });
      sidebar.addEventListener("click", function(event3) {
        if (samePageLink(event3.target.closest("a"))) {
          toggletoc();
        }
      });
      window.addEventListener("pageshow", (e2) => {
        if (e2.persisted) {
          sidebar.classList.remove("visible");
          sidebar.classList.add("hidden");
        }
      });
    }
  });
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
    for (const childUL of listItem.querySelectorAll(":scope > ul.toc-item-list")) {
      for (const childItem of childUL.querySelectorAll(":scope > li.toc-item")) {
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
  window.addEventListener("DOMContentLoaded", function(event2) {
    if (document.querySelector(".ptx-toc.focused") === null)
      return;
    let maxDepth = 1e3;
    for (let className of document.querySelector(".ptx-toc").classList)
      if (className.length > 5 && className.slice(0, 5) === "depth")
        maxDepth = Number(className.slice(5));
    let preexpandedLevels = 1;
    let tocDataSet = document.querySelector(".ptx-toc").dataset;
    if (typeof tocDataSet.preexpandedLevels !== "undefined")
      preexpandedLevels = Number(tocDataSet.preexpandedLevels);
    let tocItems = document.querySelectorAll(".ptx-toc ul.structural > .toc-item");
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
      let hashLink = document.querySelector(`.ptx-toc a[href$="${hash}"]`);
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
  });
  window.addEventListener("DOMContentLoaded", function(event2) {
    scrollTocToActive();
  });
  window.onhashchange = scrollTocToActive;

  // ../../js/pretext_add_on.js
  window.i18next = window.i18next || {
    t(key, params = {}) {
      for (const param in params) {
        key = key.replace(`{{${param}}}`, params[param]);
      }
      return key;
    }
  };
  function getScrollbarWidth() {
    var outer = document.createElement("div");
    outer.style.visibility = "hidden";
    outer.style.width = "100px";
    outer.style.msOverflowStyle = "scrollbar";
    document.body.appendChild(outer);
    var widthNoScroll = outer.offsetWidth;
    outer.style.overflow = "scroll";
    var inner = document.createElement("div");
    inner.style.width = "100%";
    outer.appendChild(inner);
    var widthWithScroll = inner.offsetWidth;
    outer.parentNode.removeChild(outer);
    return widthNoScroll - widthWithScroll;
  }
  async function copyPermalink(linkNode) {
    if (!navigator.clipboard) {
      console.log("Error: Clipboard API not available");
      return;
    }
    console.log("copying permalink for", linkNode);
    var elem = linkNode.parentElement;
    if (!linkNode) {
      console.log("Error: Something went wrong finding permalink URL");
      return;
    }
    const this_permalink_url = linkNode.href;
    const this_permalink_description = elem.getAttribute("data-description");
    var link = '<a href="' + this_permalink_url + '">' + this_permalink_description + "</a>";
    var msg_link = '<a class="internal" href="' + this_permalink_url + '">' + this_permalink_description + "</a>";
    var text_fallback = this_permalink_description + " \r\n" + this_permalink_url;
    var copy_success = true;
    try {
      await navigator.clipboard.write([
        new ClipboardItem({
          "text/html": new Blob([link], { type: "text/html" }),
          "text/plain": new Blob([text_fallback], { type: "text/plain" })
        })
      ]);
    } catch (err) {
      console.log("Permalink-to-clipboard using ClipboardItem failed, falling back to clipboard.writeText", err);
      copy_success = false;
    }
    if (!copy_success) {
      try {
        await navigator.clipboard.writeText(text_fallback);
      } catch (err) {
        console.log("Permalink-to-clipboard using clipboard.writeText failed", err);
        console.error("Failed to copy link to clipboard!");
        return;
      }
    }
    console.log(`copied '${this_permalink_url}' to clipboard`);
    let copied_msg = document.createElement("p");
    copied_msg.setAttribute("role", "alert");
    copied_msg.className = "permalink-alert";
    copied_msg.innerHTML = "Link to " + msg_link + " copied to clipboard";
    elem.parentElement.insertBefore(copied_msg, elem);
    await new Promise((resolve, reject) => setTimeout(resolve, 1500));
    copied_msg.remove();
  }
  window.addEventListener("DOMContentLoaded", function() {
    const permalinks = document.querySelectorAll(".autopermalink > a");
    permalinks.forEach((link) => {
      link.addEventListener("click", function(event2) {
        event2.preventDefault();
        copyPermalink(link);
      });
    });
  });
  window.addEventListener(
    "load",
    function(event2) {
      $("body").on("click", ".image-box > img:not(.draw_on_me):not(.mag_popup), .sbspanel > img:not(.draw_on_me):not(.mag_popup), figure > img:not(.draw_on_me):not(.mag_popup), figure > div > img:not(.draw_on_me):not(.mag_popup)", function() {
        var img_big = document.createElement("div");
        const content_element = document.getElementById("ptx-content");
        img_big.setAttribute("class", "mag_popup_container");
        img_big.innerHTML = `<img src="${$(this).attr("src")}" style="width:100%;" class="mag_popup"/>`;
        place_to_put_big_img = $(this).parents(".image-box, .sbsrow, figure, li, .cols2 article:nth-of-type(2n)").last();
        if (place_to_put_big_img.prop("tagName") == "ARTICLE") {
          place_to_put_big_img = place_to_put_big_img.prev().children().first();
        }
        var img_big_parent = place_to_put_big_img[0].parentElement;
        while (img_big_parent.id !== "ptx-content") {
          const computed_position = getComputedStyle(img_big_parent).position;
          if (computed_position !== "static") {
            break;
          }
          img_big_parent = img_big_parent.parentElement;
        }
        const content_element_computed_style = getComputedStyle(content_element);
        const content_padding_left = parseFloat(content_element_computed_style.paddingLeft);
        const content_padding_right = parseFloat(content_element_computed_style.paddingRight);
        const img_big_offset = content_element.getBoundingClientRect().left - img_big_parent.getBoundingClientRect().left + content_padding_left;
        const doc_width = content_element.offsetWidth - content_padding_left - content_padding_right;
        img_big.setAttribute("style", `width:${doc_width.toString()}px; left:${img_big_offset.toString()}px;`);
        $(img_big).insertBefore(place_to_put_big_img);
      });
      $("body").on("click", "img.mag_popup", function() {
        this.parentNode.remove();
      });
      p_no_id = document.querySelectorAll(".main p:not([id])");
      for (var n = p_no_id.length - 1; n >= 0; --n) {
        e = p_no_id[n];
        if (e.hasAttribute("id")) {
          continue;
        }
        if (e.classList.contains("watermark")) {
          console.log(e, "skipping the watermark");
          continue;
        }
        prev_p = $(e).prevAll("p");
        console.log("prev_p", prev_p, "xx");
        if (prev_p.length == 0) {
          console.log("   PPP   problem: prev_p has no length:", prev_p);
          continue;
        }
        console.log("which has id", prev_p[0].id);
        var parts_found = 1;
        var parts_to_id = [e];
        for (var i = 0; i < prev_p.length; ++i) {
          this_previous = prev_p[i];
          console.log("i", i, "this_previous", this_previous, "id", this_previous.id, "???", this_previous.hasAttribute("id"));
          if (!this_previous.hasAttribute("id")) {
            parts_to_id.unshift(this_previous);
          } else {
            base_id = this_previous.id;
            console.log("base_id", base_id);
            console.log("ready to add id to", parts_to_id);
            for (var j = 0; j < parts_to_id.length; ++j) {
              ++parts_found;
              var next_id = base_id + "-part" + parts_found.toString();
              console.log("parts_found", parts_found, "next_id", next_id);
              parts_to_id[j].setAttribute("id", next_id);
            }
            break;
          }
        }
      }
      console.log("adding video popouts");
      all_iframes = document.querySelectorAll("body iframeXXXX");
      for (var i = 0; i < all_iframes.length; i++) {
        this_item = all_iframes[i];
        this_item_src = this_item.src;
        if (this_item_src.includes("youtube")) {
          this_item_id = this_item.id;
          this_item_width = this_item.width;
          this_item_height = this_item.height;
          if (this_item_height < 150) {
            continue;
          }
          console.log("found a youtube video on", this_item_id);
          var empty_div = document.createElement("div");
          var this_videomag_container = document.createElement("div");
          parent_tag = this_item.parentElement.tagName;
          if (parent_tag == "FIGURE") {
            this_videomag_container.setAttribute("class", "videobig");
          } else {
            this_videomag_container.setAttribute("class", "videobig nofigure");
          }
          this_videomag_container.setAttribute("video-id", this_item_id);
          this_videomag_container.setAttribute("data-width", this_item_width);
          this_videomag_container.setAttribute("data-height", this_item_height);
          this_videomag_container.innerHTML = "fit width";
          this_item.insertAdjacentElement("beforebegin", empty_div);
          this_item.insertAdjacentElement("beforebegin", this_videomag_container);
          this_item.insertAdjacentElement("beforebegin", empty_div);
        }
      }
      $(".videobig").click(function() {
        parent_video_id = this.getAttribute("video-id");
        console.log("clicked videobig for", parent_video_id);
        this_video = document.getElementById(parent_video_id);
        console.log("make big: ", this_video);
        original_width = this.getAttribute("data-width");
        original_height = this.getAttribute("data-height");
        browser_width = $(window).width();
        width_ratio = browser_width / original_width;
        console.log("the browser is wider by a factor of", width_ratio);
        this_video.setAttribute("width", width_ratio * original_width);
        this_video.setAttribute("height", width_ratio * original_height);
        this_video.setAttribute("style", "position:relative; left:-260px; z-index:1000");
        this.setAttribute("class", "videosmall");
        this.innerHTML = "make small";
        $(".videosmall").click(function() {
          console.log("clicked videosmall");
          parent_video_id = this.getAttribute("video-id");
          this_video = document.getElementById(parent_video_id);
          original_width = this.getAttribute("data-width");
          original_height = this.getAttribute("data-height");
          this_video.removeAttribute("style");
          this_video.setAttribute("width", original_width);
          this_video.setAttribute("height", original_height);
          this.setAttribute("class", "videobig");
          this.innerHTML = "fit width";
        });
      });
    },
    false
  );
  function process_workspace() {
    console.log("processing workspace");
    MathJax.typesetPromise();
  }
  function pretext_geogebra_calculator_onload() {
    $("#calculator-toggle").focus();
    var inputfield = $("input.gwt-SuggestBox.TextField")[0];
    console.log("inputfield", inputfield);
    inputfield.focus();
  }
  window.addEventListener("load", function(event2) {
    var scrollWidth = getScrollbarWidth();
    if (navigator.userAgent.match(/Mozilla/i) != null) {
    }
    console.log("scrollWidth", scrollWidth);
    calcoffsetR = 5;
    calcoffsetB = 5;
    $("body").on("mouseover", "#geogebra-calculator canvas", function() {
      $("body").css("overflow", "hidden");
      $("html").css("margin-right", "15px");
      $("#calculator-container").css("right", (calcoffsetR + scrollWidth).toString() + "px");
      $("#calculator-container").css("bottom", (calcoffsetB + scrollWidth).toString() + "px");
    });
    $("body").on("mouseout", "#geogebra-calculator canvas", function() {
      $("body").css("overflow", "scroll");
      $("html").css("margin-right", "0");
      $("#calculator-container").css("right", calcoffsetR.toString() + "px");
      $("#calculator-container").css("bottom", calcoffsetB.toString() + "px");
    });
    $("body").on("click", "#calculator-toggle", function() {
      if ($("#calculator-container").css("display") == "none") {
        $("#calculator-container").css("display", "block");
        $("#calculator-toggle").addClass("open");
        $("#calculator-toggle").attr("title", "Hide calculator");
        $("#calculator-toggle").attr("aria-expanded", "true");
        create_calc_script = document.getElementById("create_ggb_calc");
        if (!create_calc_script) {
          var ggbscript = document.createElement("script");
          ggbscript.id = "create_ggb_calc";
          ggbscript.innerHTML = "ggbApp.inject('geogebra-calculator')";
          document.body.appendChild(ggbscript);
        } else {
          pretext_geogebra_calculator_onload();
        }
      } else {
        $("#calculator-container").css("display", "none");
        $("#calculator-toggle").removeClass("open");
        $("#calculator-toggle").attr("title", "Show calculator");
        $("#calculator-toggle").attr("aria-expanded", "false");
      }
    });
  });
  window.addEventListener(
    "load",
    function(event2) {
      document.onkeyup = function(event3) {
        var e2 = !event3 ? window.event : event3;
        switch (e2.keyCode) {
          case 13:
            just_hit_escape = false;
            if ($(document.activeElement).hasClass("workspace")) {
              process_workspace();
            }
          case 27:
            var parent_sage_cell = document.activeElement.closest(".sagecell_editor");
            if (parent_sage_cell && !just_hit_escape) {
              console.log("staying in the sage cell", parent_sage_cell, document.activeElement);
              just_hit_escape = true;
              setTimeout(function() {
                just_hit_escape = false;
              }, 1e3);
            } else if (knowl_focus_stack.length > 0) {
              most_recently_opened = knowl_focus_stack.pop();
              knowl_focus_stack_uid.pop();
              most_recently_opened.focus();
              console.log("moved back one knowl");
            } else {
              console.log("no open knowls being tracked");
              break;
            }
            break;
        }
      };
    },
    false
  );
  window.addEventListener("load", function(event2) {
    if (window.location.hash.length) {
      let id = window.location.hash.substring(1);
      var the_anchor = document.getElementById(id);
      console.log("id", id, "the_anchor", the_anchor);
      if (the_anchor.tagName == "ARTICLE") {
        var contained_knowl = the_anchor.querySelector("a[data-knowl]");
        if (contained_knowl && contained_knowl.parentElement == the_anchor) {
          console.log("found a knowl", contained_knowl);
          contained_knowl.click();
        }
      } else if (the_anchor.hasAttribute("data-knowl")) {
        the_anchor.click();
      } else {
        var this_hidden_content = the_anchor.closest(".hidden-content");
        if (this_hidden_content) {
          console.log("linked to a hidden knowl with this_hidden_content", this_hidden_content);
          var the_refid = this_hidden_content.id;
          var this_knowl = document.querySelector('[data-refid="' + the_refid + '"]');
          this_knowl.click();
        }
      }
    }
  });
  function flattenParagraphsSections(printout) {
    const paragraphsSections = printout.querySelectorAll("section.paragraphs");
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
        promises.push(new Promise((resolve) => {
          img.addEventListener("load", resolve, { once: true });
          img.addEventListener("error", resolve, { once: true });
        }));
      }
    }
    if (promises.length === 0) return Promise.resolve();
    return Promise.race([
      Promise.all(promises),
      new Promise((resolve) => setTimeout(resolve, timeoutMs))
    ]);
  }
  function setInitialWorkspaceHeights() {
    const workspaces = document.querySelectorAll(".workspace");
    workspaces.forEach((ws) => {
      ws.style.height = ws.getAttribute("data-space") || "0px";
      ws.setAttribute("contenteditable", "true");
    });
  }
  function adjustPrintoutPages() {
    console.log("*** Adjusting printout pages.");
    const printout = document.querySelector("section.worksheet, section.handout");
    if (!printout) {
      console.warn("No printout found, exiting adjustPrintoutPages.");
      return;
    }
    const pages = printout.querySelectorAll(".onepage");
    if (pages.length === 0) {
      console.warn("No pages found in printout, exiting adjustPrintoutPages.");
      return;
    }
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
    console.log("Moved all content before the first page and after the last page into the respective pages.");
  }
  function createPrintoutPages(margins) {
    console.log("*** Creating printout pages with margins:", margins);
    const conservativeContentHeight = 1056 - (margins.top + margins.bottom);
    const conservativeContentWidth = 794 - (margins.left + margins.right);
    const printout = document.querySelector("section.worksheet, section.handout");
    if (!printout) {
      console.warn("No printout found, exiting createPrintoutPages.");
      return;
    }
    printout.style.width = toString(conservativeContentWidth + margins.left + margins.right) + "px";
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
      if (blockHeight === 0) {
        console.log("Skipping row with zero height:", row);
        continue;
      }
      let totalWorkspaceHeight = 0;
      if (row.querySelector(".workspace")) {
        totalWorkspaceHeight = getElemWorkspaceHeight(row);
      }
      blockList.push({ elem: row, height: blockHeight, workspaceHeight: totalWorkspaceHeight });
    }
    const pageBreaks = findPageBreaks(blockList, conservativeContentHeight);
    for (let i = 0; i < pageBreaks.length; i++) {
      const pageDiv = document.createElement("section");
      pageDiv.classList.add("onepage");
      if (i === 0) {
        pageDiv.classList.add("firstpage");
      }
      if (i === pageBreaks.length - 1) {
        pageDiv.classList.add("lastpage");
      }
      const start = pageBreaks[i - 1] || 0;
      const end = pageBreaks[i];
      for (let j = start; j < end; j++) {
        const row = blockList[j].elem;
        pageDiv.appendChild(row);
      }
      printout.appendChild(pageDiv);
    }
    for (const child of printout.children) {
      if (!child.classList.contains("onepage")) {
        console.log("Removing old child not in a page:", child);
        printout.removeChild(child);
      }
    }
  }
  function addHeadersAndFootersToPrintout() {
    const printout = document.querySelector("section.worksheet, section.handout");
    if (!printout) {
      console.warn("No printout found, exiting addHeadersAndFootersToPrintout.");
      return;
    }
    const pages = printout.querySelectorAll(".onepage");
    pages.forEach((page, index) => {
      const isFirstPage = index === 0;
      const headerDiv = document.createElement("div");
      headerDiv.classList.add(isFirstPage ? "first-page-header" : "running-header", "hidden");
      headerDiv.innerHTML = `<div class="header-left" contenteditable="true"></div><div class="header-center" contenteditable="true"></div><div class="header-right" contenteditable="true"></div>`;
      page.insertBefore(headerDiv, page.firstChild);
      const footerDiv = document.createElement("div");
      footerDiv.classList.add(isFirstPage ? "first-page-footer" : "running-footer", "hidden");
      footerDiv.innerHTML = `<div class="footer-left" contenteditable="true"></div><div class="footer-center" contenteditable="true"></div><div class="footer-right" contenteditable="true"></div>`;
      page.appendChild(footerDiv);
    });
    const headerFooterKeys = ["header-first-left", "header-first-center", "header-first-right", "footer-first-left", "footer-first-center", "footer-first-right", "header-running-left", "header-running-center", "header-running-right", "footer-running-left", "footer-running-center", "footer-running-right"];
    const headerFooterContent = {};
    headerFooterKeys.forEach((key) => {
      headerFooterContent[key] = localStorage.getItem(key) || printout.getAttribute(`data-${key}`) || "";
    });
    document.querySelector(".first-page-header").querySelector(".header-left").innerHTML = headerFooterContent["header-first-left"];
    document.querySelector(".first-page-header").querySelector(".header-center").innerHTML = headerFooterContent["header-first-center"];
    document.querySelector(".first-page-header").querySelector(".header-right").innerHTML = headerFooterContent["header-first-right"];
    document.querySelector(".first-page-footer").querySelector(".footer-left").innerHTML = headerFooterContent["footer-first-left"];
    document.querySelector(".first-page-footer").querySelector(".footer-center").innerHTML = headerFooterContent["footer-first-center"];
    document.querySelector(".first-page-footer").querySelector(".footer-right").innerHTML = headerFooterContent["footer-first-right"];
    document.querySelectorAll(".running-header").forEach((headerDiv) => {
      headerDiv.querySelector(".header-left").innerHTML = headerFooterContent["header-running-left"];
      headerDiv.querySelector(".header-center").innerHTML = headerFooterContent["header-running-center"];
      headerDiv.querySelector(".header-right").innerHTML = headerFooterContent["header-running-right"];
    });
    document.querySelectorAll(".running-footer").forEach((footerDiv) => {
      footerDiv.querySelector(".footer-left").innerHTML = headerFooterContent["footer-running-left"];
      footerDiv.querySelector(".footer-center").innerHTML = headerFooterContent["footer-running-center"];
      footerDiv.querySelector(".footer-right").innerHTML = headerFooterContent["footer-running-right"];
    });
    headerFooterKeys.forEach((key) => {
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
      const elements = document.querySelectorAll(selectorMap[key]);
      elements.forEach((elem) => {
        elem.addEventListener("input", () => {
          localStorage.setItem(key, elem.innerHTML);
        });
      });
    });
  }
  function adjustWorkspaceToFitPage({ paperSize, margins }) {
    console.log("*** Adjusting workspace to fit page size:", paperSize, "with margins:", margins);
    const highlightWorkspaceCheckbox = document.getElementById("highlight-workspace-checkbox");
    const wasHighlighted = highlightWorkspaceCheckbox && highlightWorkspaceCheckbox.checked;
    if (wasHighlighted) {
      toggleWorkspaceHighlight(false);
    }
    let paperWidth, paperHeight;
    if (paperSize === "a4" || document.body.classList.contains("a4")) {
      console.log("Setting page size to A4");
      paperWidth = 794;
      paperHeight = 1122.5;
    } else {
      console.log("Setting page size to Letter");
      paperWidth = 816;
      paperHeight = 1056;
    }
    const paperContentHeight = paperHeight - (margins.top + margins.bottom);
    setInitialWorkspaceHeights();
    const pages = document.querySelectorAll(".onepage");
    pages.forEach((page) => {
      console.log("Adjusting workspace height for page:", page);
      page.style.width = paperWidth + "px";
      const rows = page.children;
      let totalContentHeight = 0;
      let totalWorkspaceHeight = 0;
      for (const row of rows) {
        totalContentHeight += getElementTotalHeight(row);
        totalWorkspaceHeight += getElemWorkspaceHeight(row);
      }
      if (totalWorkspaceHeight === 0) {
        console.log("No workspaces on this page, skipping workspace adjustment.");
        page.style.width = "";
        return;
      }
      const extraHeight = paperContentHeight - totalContentHeight;
      console.log("Extra height to distribute across workspaces:", extraHeight, "px.");
      const workspaceAdjustmentFactor = (totalWorkspaceHeight + extraHeight) / totalWorkspaceHeight;
      console.log("Workspace adjustment factor for page:", workspaceAdjustmentFactor);
      const pageWorkspaces = page.querySelectorAll(".workspace");
      pageWorkspaces.forEach((ws) => {
        const originalHeight = ws.offsetHeight;
        const newHeight = originalHeight * workspaceAdjustmentFactor;
        ws.style.height = newHeight + "px";
      });
      page.style.width = "";
    });
    console.log("Set page sizes to content area of paper size.");
    if (wasHighlighted) {
      toggleWorkspaceHighlight(true);
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
          console.log("Found exercisegroup with columns:", columns);
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
  function findPageBreaks(rows, pageHeight) {
    console.log("*** Finding page breaks for", rows.length, "rows with page height:", pageHeight);
    let pageBreaks = [];
    let minCost = Array(rows.length + 1).fill(Infinity);
    minCost[rows.length] = 0;
    let nextPageBreak = Array(rows.length).fill(-1);
    for (let i = rows.length - 1; i >= 0; i--) {
      let cumulativeHeight = 0;
      let cumulativeWorkspaceHeight = 0;
      for (let j = i; j < rows.length; j++) {
        cumulativeHeight += rows[j].height;
        cumulativeWorkspaceHeight += rows[j].workspaceHeight;
        if (cumulativeHeight > pageHeight) {
          if (j === i) {
            console.log("Row", i, "exceeds page height by itself, setting as its own page.");
            minCost[i] = 0;
            nextPageBreak[i] = i + 1;
            break;
          } else {
            break;
          }
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
  function setPageGeometryCSS({ paperSize, margins }) {
    console.log("*** Setting page geometry CSS for paper size:", paperSize, "with margins:", margins);
    const existingStyle = document.getElementById("page-geometry-css");
    if (existingStyle) {
      existingStyle.remove();
    }
    let wsWidth = paperSize === "letter" ? "816px" : "794px";
    let wsHeight = paperSize === "letter" ? "1056px" : "1123px";
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
  function toggleWorkspaceHighlight(isChecked) {
    if (isChecked) {
      document.body.classList.add("highlight-workspace");
      if (!document.querySelector(".workspace-container")) {
        console.log("adding original workspace divs");
        document.querySelectorAll(".workspace").forEach((workspace) => {
          const container = document.createElement("div");
          container.classList.add("workspace-container");
          container.style.height = window.getComputedStyle(workspace).height;
          const original = document.createElement("div");
          original.classList.add("original-workspace");
          const originalHeight = workspace.getAttribute("data-space") || "0px";
          original.setAttribute("title", "Author-specified workspace height (" + originalHeight + ")");
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
  function getPaperSize() {
    let paperSize = localStorage.getItem("papersize");
    if (paperSize) {
      return paperSize;
    } else {
      try {
        fetch("https://ipapi.co/json/").then((response) => response.json()).then((data) => {
          let continent = data && data.continent_code ? data.continent_code : "";
          paperSize = continent === "NA" || continent === "SA" ? "letter" : "a4";
          const radio = document.querySelector(`input[name="papersize"][value="${paperSize}"]`);
          if (radio) {
            radio.checked = true;
            localStorage.setItem("papersize", paperSize);
          }
          document.body.classList.remove("a4", "letter");
          document.body.classList.add(paperSize);
          console.log("Setting papersize to", paperSize);
        }).catch((err) => {
          throw err;
        });
      } catch (e2) {
        const radio = document.querySelector(`input[name="papersize"][value="letter"]`);
        if (radio) radio.checked = true;
      }
    }
    return paperSize || "letter";
  }
  async function loadPrintout(printableSectionID) {
    const themeStylesheetLink = document.querySelector('link[rel="stylesheet"][href*="theme"]');
    const themeStylesheetHref = themeStylesheetLink ? themeStylesheetLink.getAttribute("href") : null;
    if (themeStylesheetHref) {
      const printStylesheetHref = themeStylesheetHref.replace(/theme.*\.css/, "print-worksheet.css");
      themeStylesheetLink.setAttribute("href", printStylesheetHref);
      await new Promise((resolve) => {
        themeStylesheetLink.addEventListener("load", resolve, { once: true });
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
  function rewriteSolutions() {
    var born_hidden_knowls = document.querySelectorAll(".worksheet details, .handout details");
    born_hidden_knowls.forEach(function(detail) {
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
  window.addEventListener("DOMContentLoaded", async function(event2) {
    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.has("printpreview")) {
      const printableSectionID = urlParams.get("printpreview");
      await loadPrintout(printableSectionID);
      const marginList = document.querySelector("section.worksheet, section.handout").getAttribute("data-margins").split(" ");
      const margins = {
        top: toPixels(marginList[0] || "0.75in"),
        // Default to 0.75in if not specified
        right: toPixels(marginList[1] || "0.75in"),
        bottom: toPixels(marginList[2] || "0.75in"),
        left: toPixels(marginList[3] || "0.75in")
      };
      rewriteSolutions();
      let paperSize = getPaperSize();
      if (paperSize) {
        const radio = document.querySelector(`input[name="papersize"][value="${paperSize}"]`);
        if (radio) {
          radio.checked = true;
        }
        document.body.classList.remove("a4", "letter");
        document.body.classList.add(paperSize);
        setPageGeometryCSS({ paperSize, margins });
      } else {
        console.warning("Bug: paperSize should always have a value here.");
      }
      const papersizeRadios = document.querySelectorAll('input[name="papersize"]');
      papersizeRadios.forEach((radio) => {
        radio.addEventListener("change", function() {
          if (this.checked) {
            document.body.classList.remove("a4", "letter");
            document.body.classList.add(this.value);
            localStorage.setItem("papersize", this.value);
            setPageGeometryCSS({ paperSize: this.value, margins });
            adjustWorkspaceToFitPage({ paperSize: this.value, margins });
          }
        });
      });
      for (const solutionType of ["hint", "answer", "solution"]) {
        const checkbox = document.getElementById(`hide-${solutionType}-checkbox`);
        if (checkbox) {
          const storageKey = `hide-${solutionType}`;
          if (solutionType === "answer" || solutionType === "solution") {
            if (!localStorage.getItem(storageKey)) {
              checkbox.checked = true;
              localStorage.setItem(storageKey, "true");
            }
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
      }
      const printoutSection = document.querySelector("section.worksheet, section.handout");
      if (printoutSection) {
        flattenParagraphsSections(printoutSection);
      }
      if (printoutSection) {
        await waitForImages(printoutSection);
      }
      if (document.querySelector(".onepage")) {
        adjustPrintoutPages();
      } else {
        createPrintoutPages(margins);
      }
      addHeadersAndFootersToPrintout();
      for (const hf of ["first-page-header", "running-header", "first-page-footer", "running-footer"]) {
        const checkbox = document.getElementById(`print-${hf}-checkbox`);
        if (checkbox) {
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
      }
      adjustWorkspaceToFitPage({ paperSize, margins });
      const highlightWorkspaceCheckbox = document.getElementById("highlight-workspace-checkbox");
      if (highlightWorkspaceCheckbox) {
        highlightWorkspaceCheckbox.checked = localStorage.getItem("highlightWorkspace") === "true";
        highlightWorkspaceCheckbox.addEventListener("change", function() {
          localStorage.setItem("highlightWorkspace", this.checked);
          toggleWorkspaceHighlight(this.checked);
        });
        toggleWorkspaceHighlight(highlightWorkspaceCheckbox.checked);
      }
      console.log("finished adjusting workspace");
    }
  });
  function isDarkMode() {
    if (document.documentElement.dataset.darkmode === "disabled")
      return false;
    const currentTheme = localStorage.getItem("theme");
    if (currentTheme === "dark")
      return true;
    else if (currentTheme === "light")
      return false;
    return window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches;
  }
  function setDarkMode(isDark) {
    if (document.documentElement.dataset.darkmode === "disabled")
      return;
    const parentHtml = document.documentElement;
    const iframes = document.querySelectorAll("iframe[data-dark-mode-enabled]");
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
      modeButton.querySelector(".name").innerText = isDark ? window.i18next.t("Light Mode") : window.i18next.t("Dark Mode");
    }
  }
  setDarkMode(isDarkMode());
  window.addEventListener("DOMContentLoaded", function(event2) {
    const isDark = isDarkMode();
    setDarkMode(isDark);
    const modeButton = document.getElementById("light-dark-button");
    modeButton.addEventListener("click", function() {
      const wasDark = isDarkMode();
      setDarkMode(!wasDark);
      localStorage.setItem("theme", wasDark ? "light" : "dark");
    });
  });
  var PTXDialog = class _PTXDialog {
    static hasNativeCommandInvokers() {
      return "commandForElement" in HTMLButtonElement.prototype;
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
      this.openButton = openButton;
      if (this.openButton && !_PTXDialog.hasNativeCommandInvokers()) {
        this.openButton.addEventListener("click", () => this.open());
      }
      this.closeButton = options.closeButton;
      if (!this.closeButton && this.isModal) {
        const topBar = document.createElement("div");
        topBar.classList.add("ptx-dialog-topbar");
        this.dialog.prepend(topBar);
        this.closeButton = document.createElement("button");
        this.closeButton.classList.add("ptx-dialog-close-button");
        this.closeButton.setAttribute("aria-label", "Close dialog");
        this.closeButton.innerHTML = `<span class="material-symbols-outlined">close</span>`;
        topBar.appendChild(this.closeButton);
      }
      if (this.closeButton) {
        this.closeButton.addEventListener("click", () => this.close());
      }
      if (_PTXDialog.hasNativeCommandInvokers()) {
        this.open = () => {
          if (this.isModal) {
            this.dialog.showModal();
          } else {
            this.dialog.show();
          }
        };
        this.close = () => {
          this.dialog.close();
          if (this.controlElement) {
            this.controlElement.focus();
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
        this.open = () => this.openDialogFallback();
        this.close = () => this.closeDialogFallback();
        this.toggle = () => this.toggleDialogFallback();
      }
      if (this.kind === "light-close") {
        this.dialog.addEventListener("click", (event2) => {
          if (event2.target === this.dialog) {
            const rect = this.dialog.getBoundingClientRect();
            const isInDialog = rect.top <= event2.clientY && event2.clientY <= rect.top + rect.height && rect.left <= event2.clientX && event2.clientX <= rect.left + rect.width;
            if (!isInDialog) {
              this.close();
            }
          }
        });
      }
    }
    openDialogFallback() {
      if (this.dialog && typeof this.dialog.showModal === "function" && !this.dialog.open) {
        if (this.isModal) {
          this.dialog.showModal();
        } else {
          this.dialog.show();
        }
      }
    }
    closeDialogFallback() {
      if (this.dialog && typeof this.dialog.close === "function" && this.dialog.open) {
        this.dialog.close();
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
  };
  window.addEventListener("DOMContentLoaded", function(event2) {
    const shareButton = document.getElementById("ptx-embed-button");
    const sharePopupElement = document.getElementById("ptx-embed-popup");
    if (!shareButton || !sharePopupElement) {
      return;
    }
    const closeBtn = document.getElementById("ptx-embed-close-button");
    const sharePopup = new PTXDialog(
      sharePopupElement,
      shareButton,
      {
        kind: "light-close",
        closeButton: closeBtn
      }
    );
    const embedCode = "<iframe src='" + window.location.href + "?embed' width='100%' height='1000px' frameborder='0'></iframe>";
    const embedTextbox = document.getElementById("ptx-embed-code-textbox");
    if (embedTextbox) {
      embedTextbox.value = embedCode;
    }
    const copyButton = document.getElementById("ptx-embed-copy-button");
    if (copyButton) {
      if (navigator.clipboard) {
        copyButton.addEventListener("click", function() {
          const embedTextbox2 = document.getElementById("ptx-embed-code-textbox");
          if (embedTextbox2) {
            if (navigator.clipboard) {
              navigator.clipboard.writeText(embedCode).then(() => {
                console.log("Embed code copied to clipboard!");
                copyButton.querySelector(".icon").innerText = "library_add_check";
                setTimeout(function() {
                  copyButton.querySelector(".icon").innerText = "content_copy";
                  sharePopup.close();
                  shareButton.focus();
                }, 450);
              }).catch((err) => {
                console.error("Failed to copy embed code: ", err);
              });
            } else {
              console.warn("Clipboard API not supported, falling back to manual copy.");
            }
          }
        });
      } else {
        copyButton.style.display = "none";
      }
    }
  });
  window.addEventListener("DOMContentLoaded", function(event2) {
    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.has("embed")) {
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
      for (let id of elemsToHide) {
        const elem = document.getElementById(id);
        if (elem) {
          elem.classList.add("hidden");
        }
      }
    }
  });
  document.addEventListener("click", (ev) => {
    const codeBox = ev.target.closest(".clipboardable");
    if (!navigator.clipboard || !codeBox) return;
    const button = ev.target.closest(".code-copy");
    const preContent = codeBox.querySelector("pre").textContent;
    navigator.clipboard.writeText(preContent);
    button.classList.toggle("copied");
    setTimeout(() => button.classList.toggle("copied"), 1e3);
  });
  document.addEventListener("DOMContentLoaded", () => {
    const elements = document.querySelectorAll(".clipboardable");
    for (el of elements) {
      const div = document.createElement("div");
      div.classList.add("clipboardable");
      el.classList.remove("clipboardable");
      el.replaceWith(div);
      div.insertAdjacentElement("afterbegin", el);
      div.insertAdjacentHTML("beforeend", `
    <button class="code-copy" title="Copy code" role="button" aria-label="Copy code" >
        <span class="copyicon material-symbols-outlined">content_copy</span>
        <span class="checkmark material-symbols-outlined">check</span>
    </button>
            `.trim());
    }
  });
  window.PTXDialog = PTXDialog;
  window.isDarkMode = isDarkMode;

  // ../../js/src/pretext-core.js
  var import_knowl = __toESM(require_knowl());
})();
//# sourceMappingURL=pretext-core.js.map
