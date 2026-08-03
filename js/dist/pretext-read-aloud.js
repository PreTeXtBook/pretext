(() => {
  // ../../js/src/read-aloud/nodes.js
  var FAMILIES = /* @__PURE__ */ new Set([
    "theorem-like",
    "definition-like",
    "example-like",
    "project-like",
    "remark-like",
    "computation-like",
    "assemblage-like",
    "goal-like",
    "openproblem-like",
    "exercise-like",
    "solution-like",
    "discussion-like",
    "aside-like",
    "figure-like",
    "table-like"
  ]);
  var DIVISIONS = /* @__PURE__ */ new Set([
    "article",
    "chapter",
    "section",
    "subsection",
    "subsubsection",
    "appendix",
    "exercises",
    "worksheet",
    "introduction",
    "conclusion",
    "paragraphs",
    "reading-questions",
    "references",
    "solutions",
    "glossary",
    "backmatter",
    "frontmatter"
  ]);
  var BARE_BLOCKS = /* @__PURE__ */ new Set(["proof", "hiddenproof"]);
  var ASIDE_CLASSES = {
    "born-hidden-knowl": null,
    // type comes from its own block classes
    "ptx-footnote": "footnote",
    "image-description": "description"
  };
  function nodeDescriptor(el) {
    const classes = el.classList;
    if (!classes || classes.length === 0) return null;
    let family = null;
    let type = null;
    let aside = false;
    for (const name of classes) {
      if (FAMILIES.has(name)) {
        family = name;
      } else if (name in ASIDE_CLASSES) {
        aside = true;
        if (ASIDE_CLASSES[name]) type = ASIDE_CLASSES[name];
      }
    }
    if (family && !type) {
      type = classes[0] === family ? family : classes[0];
    }
    if (!type && BARE_BLOCKS.has(classes[0])) {
      type = classes[0];
    }
    if (!type && el.tagName === "SECTION" && DIVISIONS.has(classes[0])) {
      type = classes[0];
      family = "division";
    }
    return type ? { el, type, family, aside } : null;
  }

  // ../../js/src/read-aloud/collector.js
  var ANNOUNCE_SELECTORS = [
    { selector: ".table-like, table", stringId: "read-aloud-skip-table" },
    {
      selector: "pre, .code-box, .program, .console, .sage, .sagecell-practice, .ac_code_div, .sortable-code-container",
      stringId: "read-aloud-skip-code"
    },
    {
      selector: "iframe, audio, video, .video-box, .jxgbox, .interactive-iframe-container, .exercise-interactive",
      stringId: "read-aloud-skip-interactive"
    }
  ];
  var RUNESTONE_SELECTOR = ".ptx-runestone-container, .runestone";
  var RUNESTONE_READY = ".runestone-component-ready";
  var RUNESTONE_CAPTION = ".runestone_caption";
  var RUNESTONE_UNBUILT = "[data-component]";
  var RUNESTONE_CONTROL_SELECTOR = [
    "button",
    "input",
    "textarea",
    "select",
    // ActiveCode's toolbar, whose history slider reads out as "Original - 1
    // of 1" — a control's state, not anything the exercise says.
    ".ac_actions",
    RUNESTONE_CAPTION
  ].join(", ");
  var SKIP_SELECTOR = [
    "[aria-hidden='true']",
    "[hidden]",
    ".hidden-content",
    ".autopermalink",
    // Material Symbols draw their glyph from the element's *text*, so an icon
    // is literally the word "content_copy" or "expand_more" in the DOM.  Most
    // are marked aria-hidden already; the copy-code button's is not, and read
    // out as "content copy" beside every program listing.
    ".material-symbols-outlined",
    "mjx-assistive-mml",
    "script",
    "style",
    "noscript",
    ".ptx-content-footer",
    ".instructions",
    // WW instructor-only material
    // Runestone's drag-and-drop parks one off-screen live region per card
    // ("Incorrect drop zone for Monroe Doctrine") at the end of the page.
    // Positioned rather than hidden, so checkVisibility() reports it visible
    // and only naming it keeps it out of the reading.
    ".vh-dnd-error"
  ].join(", ");
  var CONTAINER_SELECTOR = [
    "div.para",
    "section",
    "article",
    "ul",
    "ol",
    "dl",
    "li",
    "dt",
    "dd",
    "blockquote",
    "figure",
    "details",
    // A <summary> must end its block, or an aside whose body is not itself a
    // block element (a footnote's contents div) gets appended to the title's
    // block and inherits its always-spoken status.
    "summary",
    ".exercise-statement",
    ".knowl__content",
    ".ptx-runestone-container",
    // Runestone writes real <p> for the prose it generates, where PreTeXt
    // uses div.para; without this every choice of a multiple-choice question
    // runs into the next as one block.  PreTeXt's own <p> (author bylines)
    // are standalone blocks too, so nothing else changes.
    "p",
    // One block per answer: a choice, a card to drag, a drop target.  Kept
    // separate so a listener hears them apart and can step between them.
    "label",
    "legend",
    ".draggable-drag",
    ".draggable-drop",
    ".matching-workspace .box"
  ].join(", ");
  var HEADING_SELECTOR = "h1, h2, h3, h4, h5, h6, figcaption, caption";
  var MEDIA_SELECTOR = "img, svg, canvas, iframe, video, audio, object, embed";
  function isEmptyOfContent(el) {
    if (el.textContent.trim() !== "") return false;
    return !el.matches(MEDIA_SELECTOR) && !el.querySelector(MEDIA_SELECTOR);
  }
  function readingOrder(el) {
    const children = Array.from(el.childNodes);
    const caption = el.querySelector(":scope > figcaption");
    if (!caption) return children;
    return [caption, ...children.filter((child) => child !== caption)];
  }
  function runestoneKind(el, strings = {}) {
    const caption = el.querySelector(RUNESTONE_CAPTION);
    const name = caption && caption.textContent.trim().replace(/\s+/g, " ");
    if (!name) return strings["read-aloud-interactive"] || null;
    const template = strings["read-aloud-interactive-kind"];
    return template ? template.replace("{kind}", name) : name;
  }
  function isElementVisible(el) {
    if (typeof el.checkVisibility === "function") {
      return el.checkVisibility();
    }
    return !!(el.offsetParent || el.getClientRects().length);
  }
  var MATH_REGION_MARKER = /[,;.]?\s*\bmath\b[\s.]*$/i;
  var TRAILING_PUNCTUATION = {
    comma: ",",
    period: ".",
    "full stop": ".",
    semicolon: ";",
    colon: ":",
    "question mark": "?",
    "exclamation mark": "!"
  };
  var TRAILING_PUNCTUATION_RE = new RegExp(
    `[\\s,]*\\b(${Object.keys(TRAILING_PUNCTUATION).join("|")})\\s*$`,
    "i"
  );
  function cleanMathSpeech(value) {
    if (!value) return null;
    const text = value.replace(/<[^>]*>/g, " ");
    const stripped = text.replace(MATH_REGION_MARKER, "").trim();
    const speech = (stripped || text).replace(/\s+/g, " ").trim();
    return speech.replace(
      TRAILING_PUNCTUATION_RE,
      (match, word) => TRAILING_PUNCTUATION[word.toLowerCase()]
    ) || null;
  }
  var SPEECH_ATTRIBUTES = [
    "aria-label",
    "data-semantic-speech-none",
    "data-semantic-speech"
  ];
  function speechAttribute(el, attribute) {
    const own = el.getAttribute(attribute);
    if (own) return own;
    const node = el.querySelector(`[${attribute}]`);
    return node && node.getAttribute(attribute) || null;
  }
  function readMathSpeech(el) {
    for (const attribute of SPEECH_ATTRIBUTES) {
      const raw = speechAttribute(el, attribute);
      if (raw) return cleanMathSpeech(raw);
    }
    const mml = el.querySelector("mjx-assistive-mml math");
    const alt = mml && mml.getAttribute("alttext");
    return alt ? cleanMathSpeech(alt) : null;
  }
  var mathTypeset = null;
  function whenMathTypeset(timeoutMs = 1e4) {
    if (mathTypeset) return mathTypeset;
    mathTypeset = (async () => {
      if (!window.MathJax) return;
      const deadline = Date.now() + timeoutMs;
      while (!(window.MathJax.startup && window.MathJax.startup.promise)) {
        if (Date.now() >= deadline) return;
        await new Promise((r) => setTimeout(r, 50));
      }
      await Promise.race([
        window.MathJax.startup.promise.catch(() => {
        }),
        new Promise((r) => setTimeout(r, Math.max(0, deadline - Date.now())))
      ]);
    })();
    return mathTypeset;
  }
  function resolveMathSpeech(el, timeoutMs) {
    const direct = readMathSpeech(el);
    if (direct) {
      return Promise.resolve(direct);
    }
    return new Promise((resolve) => {
      let done = false;
      const finish = (value) => {
        if (done) return;
        done = true;
        observer.disconnect();
        clearTimeout(timer);
        resolve(value);
      };
      const observer = new MutationObserver(() => {
        const speech = readMathSpeech(el);
        if (speech) finish(speech);
      });
      observer.observe(el, {
        attributes: true,
        childList: true,
        subtree: true
      });
      const timer = setTimeout(() => finish(readMathSpeech(el)), timeoutMs);
    });
  }
  async function collect(root, opts = {}) {
    const strings = opts.strings || {};
    const mathTimeoutMs = opts.mathTimeoutMs || 3e3;
    await whenMathTypeset();
    const blocks = [];
    const pendingMath = [];
    let current = null;
    const flush = () => {
      if (current && current.tokens.some(isSpeakable)) {
        blocks.push(current);
      }
      current = null;
    };
    const isSpeakable = (t) => t.kind !== "text" || t.value.trim() !== "";
    const ensureBlock = (el, ctx) => {
      if (!current) {
        current = { el, tokens: [], path: ctx.path, summary: ctx.summary };
      }
    };
    const visit = (node, blockEl, ctx) => {
      if (node.nodeType === Node.TEXT_NODE) {
        if (node.nodeValue.trim() !== "") {
          ensureBlock(blockEl, ctx);
          current.tokens.push({ kind: "text", value: node.nodeValue, node });
        }
        return;
      }
      if (node.nodeType !== Node.ELEMENT_NODE) return;
      const el = node;
      if (el.matches(SKIP_SELECTOR)) return;
      if (!ctx.closed && !isElementVisible(el)) return;
      const descriptor = nodeDescriptor(el);
      if (descriptor) {
        ctx = { ...ctx, path: ctx.path.concat(descriptor) };
      }
      if (el.tagName === "DETAILS" && !el.open) {
        ctx = { ...ctx, closed: true };
      }
      if (el.tagName === "SUMMARY") {
        ctx = { ...ctx, summary: true };
      }
      if (el.matches(".ptx-footnote__number")) {
        const label = (el.getAttribute("title") || "").trim();
        if (label) {
          flush();
          ensureBlock(el, ctx);
          current.tokens.push({ kind: "text", value: label, node: null, el });
          flush();
          return;
        }
      }
      if (!ctx.runestone && el.matches(RUNESTONE_SELECTOR)) {
        if (el.matches(RUNESTONE_READY) || el.querySelector(RUNESTONE_READY)) {
          flush();
          const kind = runestoneKind(el, strings);
          if (kind) {
            blocks.push({
              el,
              tokens: [{ kind: "text", value: kind, node: null, el }],
              path: ctx.path,
              summary: ctx.summary
            });
          }
          ctx = { ...ctx, runestone: true };
        } else if (el.matches(RUNESTONE_UNBUILT) || el.querySelector(RUNESTONE_UNBUILT)) {
          flush();
          blocks.push({
            el,
            tokens: [
              {
                kind: "announce",
                stringId: "read-aloud-skip-interactive",
                el
              }
            ],
            path: ctx.path,
            summary: ctx.summary
          });
          return;
        }
      }
      if (ctx.runestone && el.matches(RUNESTONE_CONTROL_SELECTOR)) return;
      for (const { selector, stringId } of ANNOUNCE_SELECTORS) {
        if (el.matches(selector)) {
          if (isEmptyOfContent(el)) return;
          flush();
          blocks.push({
            el,
            tokens: [{ kind: "announce", stringId, el }],
            path: ctx.path,
            summary: ctx.summary
          });
          return;
        }
      }
      if (el.tagName === "MJX-CONTAINER") {
        const display = el.getAttribute("display") === "true";
        if (display) flush();
        ensureBlock(display ? el : blockEl, ctx);
        const token = { kind: "math", speech: "", display, el };
        current.tokens.push(token);
        pendingMath.push(token);
        if (display) flush();
        return;
      }
      if (el.tagName === "IMG") {
        const alt = (el.getAttribute("alt") || "").trim();
        if (alt) {
          const label = strings["read-aloud-image-alt"];
          ensureBlock(blockEl, ctx);
          current.tokens.push({
            kind: "text",
            value: label ? `${label} ${alt}` : alt,
            node: null,
            el
          });
        }
        return;
      }
      if (el.matches(HEADING_SELECTOR) || el.matches(CONTAINER_SELECTOR)) {
        flush();
        for (const child of readingOrder(el)) visit(child, el, ctx);
        flush();
        return;
      }
      for (const child of el.childNodes) visit(child, blockEl, ctx);
    };
    visit(root, root, {
      path: [],
      summary: false,
      closed: false,
      runestone: false
    });
    flush();
    let fallbackCount = 0;
    await Promise.all(
      pendingMath.map(async (token) => {
        const speech = await resolveMathSpeech(token.el, mathTimeoutMs);
        if (!speech) fallbackCount++;
        token.speech = speech || strings["read-aloud-equation-fallback"] || "equation";
      })
    );
    if (fallbackCount) {
      console.warn(
        `PreTeXt read-aloud: no MathJax speech text for ${fallbackCount} of ${pendingMath.length} expression(s); reading the fallback instead. Run PTXReadAloud.debugMath() to see what MathJax produced.`
      );
    }
    return blocks;
  }

  // ../../js/src/read-aloud/segmenter.js
  var DEFAULT_MAX_LENGTH = 250;
  function collapseWhitespace(value) {
    let text = "";
    const map = [];
    let inSpace = false;
    for (let i = 0; i < value.length; i++) {
      if (/\s/.test(value[i])) {
        if (!inSpace && text.length > 0) {
          text += " ";
          map.push(i);
        }
        inSpace = true;
      } else {
        text += value[i];
        map.push(i);
        inSpace = false;
      }
    }
    if (text.endsWith(" ")) {
      text = text.slice(0, -1);
      map.pop();
    }
    return { text, map };
  }
  var ABBREVIATION_RE = /(?:^|[\s(\[{"'“‘])(?:Dr|Mr|Mrs|Ms|Prof|St|Mt|Fig|Eq|Ex|Sec|Ch|Thm|Cor|Lem|Def|Rem|Prop|vs|cf|No|Vol|pp?|ed|eds|etc|al|Ph\.D|(?:[A-Za-z]\.)+[A-Za-z])\.\s*$/;
  function sentenceBoundaries(text, locale) {
    let boundaries = [];
    if (typeof Intl !== "undefined" && Intl.Segmenter) {
      const seg = new Intl.Segmenter(locale || void 0, { granularity: "sentence" });
      for (const s of seg.segment(text)) {
        if (s.index > 0) {
          boundaries.push(s.index);
        }
      }
    } else {
      const re = /[.!?…]["')\]]?\s+(?=["'([]?[A-Z0-9])/g;
      let m;
      while ((m = re.exec(text)) !== null) {
        boundaries.push(m.index + m[0].length);
      }
    }
    return boundaries.filter((b) => !ABBREVIATION_RE.test(text.slice(0, b)));
  }
  function needsJoinSpace(prev, next) {
    if (prev === "" || next === "") return false;
    if (/\s$/.test(prev)) return false;
    if (/^\s/.test(next)) return false;
    if (/^[.,;:!?…)\]}%]/.test(next)) return false;
    return true;
  }
  function flattenRun(run) {
    let combined = "";
    const spans = [];
    for (const { token, tokenIndex } of run) {
      let part, map = null;
      if (token.kind === "text") {
        ({ text: part, map } = collapseWhitespace(token.value));
      } else {
        ({ text: part } = collapseWhitespace(token.speech || ""));
      }
      if (part === "") continue;
      if (needsJoinSpace(combined, part)) {
        combined += " ";
      }
      spans.push({
        start: combined.length,
        end: combined.length + part.length,
        tokenIndex,
        kind: token.kind,
        map
      });
      combined += part;
    }
    return { combined, spans };
  }
  function insideMath(pos, spans) {
    return spans.some(
      (s) => s.kind === "math" && pos > s.start && pos < s.end
    );
  }
  function clampChunks(combined, spans, start, end, maxLength) {
    const chunks = [];
    let s = start;
    while (end - s > maxLength) {
      const limit = s + maxLength;
      let cut = -1;
      const clauseCut = (i) => /[,;:—–]/.test(combined[i - 1]) && combined[i] === " ";
      const spaceCut = (i) => combined[i] === " ";
      for (const acceptable of [clauseCut, spaceCut]) {
        for (let i = limit; i > s + 1; i--) {
          if (insideMath(i, spans)) continue;
          if (acceptable(i)) {
            cut = i;
            break;
          }
        }
        if (cut >= 0) break;
      }
      if (cut < 0) {
        cut = limit;
        for (const sp of spans) {
          if (sp.kind === "math" && cut > sp.start && cut < sp.end) {
            cut = sp.end;
            break;
          }
        }
      }
      chunks.push([s, cut]);
      s = cut;
    }
    chunks.push([s, end]);
    return chunks;
  }
  function makeUtterance(combined, spans, start, end, blockIndex) {
    while (start < end && /\s/.test(combined[start])) start++;
    while (end > start && /\s/.test(combined[end - 1])) end--;
    if (start >= end) return null;
    const ranges = [];
    for (const span of spans) {
      const s = Math.max(start, span.start);
      const e = Math.min(end, span.end);
      if (s >= e) continue;
      if (span.kind === "text") {
        const localStart = s - span.start;
        const localEnd = e - span.start;
        ranges.push({
          tokenIndex: span.tokenIndex,
          start: span.map[localStart],
          end: span.map[localEnd - 1] + 1
        });
      } else {
        ranges.push({ tokenIndex: span.tokenIndex });
      }
    }
    return {
      kind: "speech",
      text: combined.slice(start, end),
      blockIndex,
      ranges
    };
  }
  function buildPlan(blocks, opts = {}) {
    const locale = opts.locale;
    const maxLength = opts.maxLength || DEFAULT_MAX_LENGTH;
    const strings = opts.strings || {};
    const plan = [];
    blocks.forEach((block, blockIndex) => {
      let run = [];
      const flushRun = () => {
        if (run.length === 0) return;
        const { combined, spans } = flattenRun(run);
        run = [];
        if (combined.trim() === "") return;
        const rawBoundaries = sentenceBoundaries(combined, locale);
        const boundaries = rawBoundaries.filter((b) => !insideMath(b, spans));
        const starts = [0, ...boundaries];
        starts.forEach((s, i) => {
          const e = i + 1 < starts.length ? starts[i + 1] : combined.length;
          for (const [cs, ce] of clampChunks(combined, spans, s, e, maxLength)) {
            const utt = makeUtterance(combined, spans, cs, ce, blockIndex);
            if (utt) plan.push(utt);
          }
        });
      };
      block.tokens.forEach((token, tokenIndex) => {
        if (token.kind === "announce") {
          flushRun();
          plan.push({
            kind: "announce",
            text: strings[token.stringId] || token.stringId,
            blockIndex,
            ranges: [{ tokenIndex }]
          });
        } else {
          run.push({ token, tokenIndex });
        }
      });
      flushRun();
    });
    return plan;
  }

  // ../../js/src/read-aloud/navigation.js
  var pathOf = (blocks, index) => blocks[index] && blocks[index].path || [];
  var pathHas = (path, node) => path.some((n) => n.el === node.el);
  function innermost(blocks, index, predicate = () => true) {
    const path = pathOf(blocks, index);
    for (let i = path.length - 1; i >= 0; i--) {
      if (predicate(path[i])) return path[i];
    }
    return null;
  }
  function enclosingBlock(blocks, index) {
    return innermost(blocks, index, (n) => n.family !== "division");
  }
  function nextBlockOutside(blocks, index, node) {
    for (let i = Math.max(0, index); i < blocks.length; i++) {
      if (!pathHas(blocks[i].path, node)) return i;
    }
    return -1;
  }
  function skipTarget(blocks, index) {
    const node = enclosingBlock(blocks, index);
    return node ? nextBlockOutside(blocks, index, node) : -1;
  }
  function blockStart(plan, planIndex) {
    const item = plan[planIndex];
    if (!item) return -1;
    let i = planIndex;
    while (i > 0 && plan[i - 1].blockIndex === item.blockIndex) i--;
    return i;
  }
  function previousBlockStart(plan, planIndex, allowed) {
    const start = blockStart(plan, planIndex);
    if (start === -1) return -1;
    if (start !== planIndex) return start;
    for (let i = start - 1; i >= 0; i--) {
      if (plan[i].blockIndex !== plan[start].blockIndex) {
        const candidate = blockStart(plan, i);
        if (!allowed || allowed(plan[candidate].blockIndex)) return candidate;
        i = candidate;
      }
    }
    return -1;
  }
  function nextBlockStart(plan, planIndex, allowed) {
    const item = plan[planIndex];
    if (!item) return -1;
    for (let i = planIndex + 1; i < plan.length; i++) {
      if (plan[i].blockIndex !== item.blockIndex) {
        if (!allowed || allowed(plan[i].blockIndex)) return i;
        const skipped = plan[i].blockIndex;
        while (i + 1 < plan.length && plan[i + 1].blockIndex === skipped) i++;
      }
    }
    return -1;
  }
  function shouldSpeak(blocks, index, mode, entered) {
    const block = blocks[index];
    if (!block) return false;
    const asides = block.path.filter((n) => n.aside);
    const gating = block.summary ? asides.slice(0, -1) : asides;
    return gating.every(
      (n) => mode === "read" || (entered ? entered.has(n.el) : false)
    );
  }
  function nextSpeakable(blocks, index, mode, entered) {
    for (let i = Math.max(0, index); i < blocks.length; i++) {
      if (shouldSpeak(blocks, i, mode, entered)) return i;
    }
    return -1;
  }

  // ../../js/src/read-aloud/speech-queue.js
  var SpeechQueue = class {
    /**
     * opts:
     *   synth        the SpeechSynthesis instance (injectable for testing)
     *   onUtterance  (index, planItem) fired as each utterance starts
     *   onState      (state) fired on every state change
     *   onEnded      () fired when the plan runs out naturally
     */
    constructor(opts = {}) {
      this.synth = opts.synth || window.speechSynthesis;
      this.onUtterance = opts.onUtterance || (() => {
      });
      this.onState = opts.onState || (() => {
      });
      this.onEnded = opts.onEnded || (() => {
      });
      this.describeBlock = opts.describeBlock || (() => null);
      this.plan = [];
      this.blocks = [];
      this.mode = opts.mode || "skip";
      this.entered = /* @__PURE__ */ new Set();
      this.pendingStart = false;
      this.index = 0;
      this.state = "idle";
      this.voice = null;
      this.rate = 1;
      this.lang = null;
      this.generation = 0;
      this.nativePause = !/Android/i.test(navigator.userAgent);
    }
    setPlan(plan, blocks) {
      this.stop();
      this.plan = plan;
      this.blocks = blocks || [];
      this.entered = /* @__PURE__ */ new Set();
      this.pendingStart = false;
      this.index = 0;
    }
    /** Change listening mode live; takes effect at the next block boundary. */
    setMode(mode) {
      this.mode = mode;
    }
    setVoice(voice) {
      this.voice = voice;
      this._restartIfSpeaking();
    }
    setRate(rate) {
      this.rate = rate;
      this._restartIfSpeaking();
    }
    setLang(lang) {
      this.lang = lang;
    }
    _setState(state) {
      if (this.state !== state) {
        this.state = state;
        this.onState(state);
      }
    }
    _restartIfSpeaking() {
      if (this.state === "speaking") {
        this.playFrom(this.index);
      }
    }
    playFrom(index) {
      if (!this.plan.length) return;
      this.generation++;
      this.synth.cancel();
      this.index = Math.max(0, Math.min(index, this.plan.length - 1));
      this._setState("speaking");
      this._speakCurrent();
    }
    _speakCurrent() {
      const item = this.plan[this.index];
      const generation = this.generation;
      const utterance = new SpeechSynthesisUtterance(item.text);
      if (this.voice) utterance.voice = this.voice;
      if (this.lang) utterance.lang = this.lang;
      utterance.rate = this.rate;
      utterance.onstart = () => {
        if (generation !== this.generation) return;
        this.onUtterance(this.index, item);
      };
      const advance = () => {
        if (generation !== this.generation) return;
        const next = this._nextIndex();
        if (next >= 0) {
          this.index = next;
          this._speakCurrent();
        } else {
          this._setState("ended");
          this.onEnded();
        }
      };
      utterance.onend = advance;
      utterance.onerror = (e) => {
        if (e.error === "canceled" || e.error === "interrupted") return;
        if (e.error === "not-allowed") {
          this._setState("idle");
          return;
        }
        advance();
      };
      this.synth.speak(utterance);
    }
    /**
     * Speak one string outside the plan, then call `done` — exactly once.
     *
     * For announcements that must be heard before something irreversible
     * happens to this queue, currently only the auto-continue warning ahead
     * of navigating away.  Neither onend nor onerror is guaranteed to arrive
     * (an engine with no voices may drop the utterance in silence), so a
     * timer backstops them: `done` is a navigation, and never firing it
     * would strand the listener on a page that has stopped reading.
     */
    speakOnce(text, done) {
      let finished = false;
      const finish = () => {
        if (finished) return;
        finished = true;
        clearTimeout(timer);
        done();
      };
      const timer = setTimeout(finish, 6e3);
      try {
        const utterance = new SpeechSynthesisUtterance(text);
        if (this.voice) utterance.voice = this.voice;
        if (this.lang) utterance.lang = this.lang;
        utterance.rate = this.rate;
        utterance.onend = finish;
        utterance.onerror = finish;
        this.synth.speak(utterance);
      } catch (e) {
        finish();
      }
    }
    pause() {
      if (this.state !== "speaking") return;
      if (this.nativePause) {
        this.synth.pause();
      } else {
        this.generation++;
        this.synth.cancel();
      }
      this._setState("paused");
    }
    resume() {
      if (this.state !== "paused") return;
      if (this.pendingStart) {
        this.pendingStart = false;
        this.enterAsideHere();
        this.playFrom(this.index);
        return;
      }
      if (this.nativePause) {
        this.synth.resume();
        this._setState("speaking");
      } else {
        this.playFrom(this.index);
      }
    }
    toggle() {
      if (this.state === "speaking") {
        this.pause();
      } else if (this.state === "paused") {
        this.resume();
      } else {
        this.playFrom(this.index);
      }
    }
    stop() {
      this.generation++;
      this.synth.cancel();
      this._setState("idle");
    }
    next() {
      const next = this._nextIndex();
      if (next >= 0) this.playFrom(next);
    }
    prev() {
      const prev = this._prevIndex();
      if (prev >= 0) this.playFrom(prev);
    }
    /** First plan index at or after the given block, for click-to-start. */
    indexForBlock(blockIndex) {
      for (let i = 0; i < this.plan.length; i++) {
        if (this.plan[i].blockIndex >= blockIndex) return i;
      }
      return -1;
    }
    /** Block index behind a plan index, or -1. */
    _blockIndex(planIndex = this.index) {
      const item = this.plan[planIndex];
      return item ? item.blockIndex : -1;
    }
    /**
     * The next plan index to speak, honouring the listening mode, or -1 at
     * the end of the page.  With no block data (console use, tests) this is
     * plain linear advance.
     */
    _nextIndex() {
      const candidate = this.index + 1;
      if (candidate >= this.plan.length) return -1;
      if (!this.blocks.length) return candidate;
      const blockIndex = this._blockIndex(candidate);
      if (shouldSpeak(this.blocks, blockIndex, this.mode, this.entered)) {
        return candidate;
      }
      const target = nextSpeakable(
        this.blocks,
        blockIndex,
        this.mode,
        this.entered
      );
      if (target < 0) return -1;
      const planIndex = this.indexForBlock(target);
      return planIndex > this.index ? planIndex : -1;
    }
    /**
     * The previous plan index to speak, or -1 at the top of the page.
     *
     * Stepping back has to honour the mode just as advancing does, or the
     * sentence after a skipped knowl steps *into* content the listener never
     * heard — going backwards through a theorem they were never read.
     */
    _prevIndex() {
      if (!this.blocks.length) return this.index > 0 ? this.index - 1 : -1;
      for (let i = this.index - 1; i >= 0; i--) {
        if (this._allowed(this.plan[i].blockIndex)) return i;
      }
      return -1;
    }
    /** Jump to a block, reporting whether there was anywhere to go. */
    _goToBlock(blockIndex) {
      if (blockIndex < 0) return false;
      const planIndex = this.indexForBlock(blockIndex);
      if (planIndex < 0) return false;
      this.playFrom(planIndex);
      return true;
    }
    /**
     * Move to the head of the previous block, or of the current one when the
     * listener is part-way through it, then announce and wait.
     */
    previousBlock() {
      return this._jumpAnnouncing(
        previousBlockStart(this.plan, this.index, (b) => this._allowed(b))
      );
    }
    /** Move to the head of the next block, then announce and wait. */
    nextBlock() {
      return this._jumpAnnouncing(
        nextBlockStart(this.plan, this.index, (b) => this._allowed(b))
      );
    }
    /**
     * If the current block is the title of an aside that is not being read,
     * mark it opened so the mode filter lets its body through.  Returns the
     * aside, or null when there was nothing to open.
     */
    enterAsideHere() {
      const block = this.blocks[this._blockIndex()];
      if (!block || !block.summary) return null;
      const asides = block.path.filter((n) => n.aside);
      const own = asides[asides.length - 1];
      if (!own || this.entered.has(own.el)) return null;
      this.entered.add(own.el);
      return own;
    }
    _allowed(blockIndex) {
      if (!this.blocks.length) return true;
      return shouldSpeak(this.blocks, blockIndex, this.mode, this.entered);
    }
    /**
     * Park at a block: say what kind of block it is, then stop and wait for
     * the listener rather than reading on.  Arrow keys are for surveying the
     * page, so landing somewhere must not commit to reading it.
     */
    _jumpAnnouncing(planIndex) {
      if (planIndex < 0) return false;
      this.generation++;
      this.synth.cancel();
      this.index = planIndex;
      this.pendingStart = true;
      const item = this.plan[planIndex];
      this.onUtterance(planIndex, item);
      const text = this.describeBlock(item.blockIndex);
      this._setState("paused");
      if (text) this._speakOnce(text);
      return true;
    }
    /** Speak one throwaway line that is not part of the plan. */
    _speakOnce(text) {
      const utterance = new SpeechSynthesisUtterance(text);
      if (this.voice) utterance.voice = this.voice;
      if (this.lang) utterance.lang = this.lang;
      utterance.rate = this.rate;
      this.synth.speak(utterance);
    }
    /** Skip the innermost theorem/example/proof and resume after it. */
    skipBlock() {
      return this._goToBlock(skipTarget(this.blocks, this._blockIndex()));
    }
  };

  // ../../js/src/read-aloud/highlighter.js
  var HIGHLIGHT_NAME = "ptx-read-aloud";
  var MATH_CLASS = "ptx-read-aloud-current-math";
  var BLOCK_CLASS = "ptx-read-aloud-current-block";
  var Highlighter = class {
    constructor() {
      this.supportsRanges = typeof CSS !== "undefined" && "highlights" in CSS;
      this.markedElements = [];
      this.autoScroll = true;
      this.scrollSuppressed = false;
      for (const evt of ["wheel", "touchmove"]) {
        window.addEventListener(evt, () => {
          this.scrollSuppressed = true;
        }, { passive: true });
      }
    }
    /** Call from explicit player actions (play/skip/click-to-start). */
    resetScrollSuppression() {
      this.scrollSuppressed = false;
    }
    show(planItem, blocks) {
      this.clear();
      const block = blocks[planItem.blockIndex];
      if (!block) return;
      const ranges = [];
      for (const r of planItem.ranges) {
        const token = block.tokens[r.tokenIndex];
        if (!token) continue;
        if (token.kind === "math") {
          token.el.classList.add(MATH_CLASS);
          this.markedElements.push({ el: token.el, cls: MATH_CLASS });
        } else if (this.supportsRanges && token.kind === "text" && token.node && token.node.isConnected) {
          try {
            const range = new Range();
            range.setStart(token.node, r.start);
            range.setEnd(token.node, r.end);
            ranges.push(range);
          } catch (e) {
          }
        }
      }
      if (this.supportsRanges && ranges.length) {
        CSS.highlights.set(HIGHLIGHT_NAME, new Highlight(...ranges));
      } else if (block.el && block.el.isConnected) {
        block.el.classList.add(BLOCK_CLASS);
        this.markedElements.push({ el: block.el, cls: BLOCK_CLASS });
      }
      if (this.autoScroll && !this.scrollSuppressed) {
        const target = block.el && block.el.isConnected && block.el || ranges.length && ranges[0].startContainer.parentElement;
        if (target && typeof target.scrollIntoView === "function") {
          target.scrollIntoView({ block: "center", behavior: "smooth" });
        }
      }
    }
    clear() {
      if (this.supportsRanges) {
        CSS.highlights.delete(HIGHLIGHT_NAME);
      }
      for (const { el, cls } of this.markedElements) {
        el.classList.remove(cls);
      }
      this.markedElements = [];
    }
  };

  // ../../js/src/read-aloud/strings.js
  var STRINGS = {
    // Toggle-button tooltips, one per state of the player's disclosure.
    "read-aloud-show": "Read aloud",
    "read-aloud-hide": "Hide reading controls",
    "read-aloud-play": "Play",
    "read-aloud-pause": "Pause",
    // Spoken in place of a block that has no useful linear reading.
    "read-aloud-skip-table": "Table. Skipping.",
    "read-aloud-skip-code": "Code. Skipping.",
    "read-aloud-skip-interactive": "Interactive element. Skipping.",
    // Spoken *before* an interactive exercise, whose prose is then read out:
    // the listener needs to know a question is coming and that answering it
    // means looking at the screen.  {kind} is Runestone's own name for the
    // component ("Multiple Choice", "Parsons", "Drag-N-Drop"), read out of
    // the page; the second form covers components that render no name.
    "read-aloud-interactive-kind": "{kind} exercise.",
    "read-aloud-interactive": "Interactive exercise.",
    // Spoken when MathJax reports no speech text for an equation.
    "read-aloud-equation-fallback": "equation",
    // Introduces an image's alt text, which is written to replace a picture
    // rather than to be read as part of the surrounding prose.
    "read-aloud-image-alt": "Image. Alt text is:",
    // Spoken at the end of a page before auto-continue navigates away.  A
    // listener with the page out of view has no other warning that they are
    // about to be somewhere else, and the pause it occupies is also their
    // chance to stop it.
    "read-aloud-continuing": "Continuing to the next page.",
    // Spoken after the name of a hidden block the listener has navigated to,
    // for the first few only: an audio interface shows no keys, so the only
    // way to learn one is to be told.
    "read-aloud-open-hint": "Press space to open.",
    // Type names for the two blocks whose headings carry no visible type: a
    // footnote shows only its number, an image description only an icon.
    // Every other block announces the name PreTeXt already renders.
    footnote: "Footnote",
    description: "Description"
  };

  // ../../js/src/read-aloud/settings.js
  var VOICE_KEY = "readAloudVoice";
  var RATE_KEY = "readAloudRate";
  var AUTOSCROLL_KEY = "readAloudAutoScroll";
  var ASIDES_KEY = "readAloudAsides";
  var AUTOCONTINUE_KEY = "readAloudAutoContinue";
  var ASIDE_MODES = ["skip", "read"];
  function getSavedAsideMode() {
    const value = localStorage.getItem(ASIDES_KEY);
    return ASIDE_MODES.includes(value) ? value : "skip";
  }
  function getSavedRate() {
    const value = Number(localStorage.getItem(RATE_KEY));
    return value >= 0.5 && value <= 2 ? value : 1;
  }
  function getSavedAutoScroll() {
    return localStorage.getItem(AUTOSCROLL_KEY) !== "false";
  }
  function getSavedAutoContinue() {
    return localStorage.getItem(AUTOCONTINUE_KEY) === "true";
  }
  function documentLang() {
    return (document.documentElement.lang || "en").toLowerCase();
  }
  function primaryLanguage(tag) {
    return (tag || "").toLowerCase().replace(/_/g, "-").split("-")[0];
  }
  function candidateVoices() {
    const all = window.speechSynthesis.getVoices();
    const lang = primaryLanguage(documentLang());
    const matching = all.filter((v) => primaryLanguage(v.lang) === lang);
    return matching.length ? matching : all;
  }
  var VOICE_QUALITY_RULES = [
    { test: /neural|natural|premium|enhanced|siri/i, score: 3 },
    { test: /google|rhvoice|piper/i, score: 2 },
    { test: /espeak|flite|festival|dummy/i, score: -1 }
  ];
  function voiceQuality(voice) {
    const name = `${voice.name} ${voice.voiceURI}`;
    const rule = VOICE_QUALITY_RULES.find((r) => r.test.test(name));
    return rule ? rule.score : 0;
  }
  function rankedVoices() {
    return candidateVoices().slice().sort(
      (a, b) => voiceQuality(b) - voiceQuality(a) || (b.default ? 1 : 0) - (a.default ? 1 : 0)
    );
  }
  var voicesReady = null;
  function whenVoicesReady(timeoutMs = 2500) {
    if (voicesReady) return voicesReady;
    voicesReady = new Promise((resolve) => {
      if (rankedVoices().length) {
        resolve();
        return;
      }
      let done = false;
      const finish = () => {
        if (done) return;
        done = true;
        clearInterval(poll);
        clearTimeout(timer);
        window.speechSynthesis.removeEventListener("voiceschanged", check);
        resolve();
      };
      const check = () => {
        if (rankedVoices().length) finish();
      };
      window.speechSynthesis.addEventListener("voiceschanged", check);
      const poll = setInterval(check, 100);
      const timer = setTimeout(finish, timeoutMs);
    });
    return voicesReady;
  }
  function getSavedVoice() {
    const voices = rankedVoices();
    const saved = localStorage.getItem(VOICE_KEY);
    if (saved) {
      const match = voices.find((v) => v.voiceURI === saved);
      if (match) return match;
    }
    return voices[0] || null;
  }
  function initSettingsControls(onChange) {
    const voiceSelect = document.getElementById("ptx-read-aloud-voice");
    const rateInput = document.getElementById("ptx-read-aloud-rate");
    const rateOutput = document.getElementById("ptx-read-aloud-rate-value");
    const autoScrollInput = document.getElementById("ptx-read-aloud-autoscroll");
    const autoContinueInput = document.getElementById("ptx-read-aloud-autocontinue");
    const asidesSelect = document.getElementById("ptx-read-aloud-asides");
    const notify = () => {
      onChange({
        voice: getSavedVoice(),
        rate: getSavedRate(),
        autoScroll: getSavedAutoScroll(),
        asideMode: getSavedAsideMode()
      });
    };
    const voiceLabel = document.querySelector('label[for="ptx-read-aloud-voice"]');
    const populateVoices = () => {
      if (!voiceSelect) return;
      const voices = rankedVoices();
      const hidden = voices.length === 0;
      voiceSelect.hidden = hidden;
      if (voiceLabel) voiceLabel.hidden = hidden;
      if (hidden) return;
      const selected = getSavedVoice();
      voiceSelect.replaceChildren();
      for (const voice of voices) {
        const option = document.createElement("option");
        option.value = voice.voiceURI;
        option.textContent = `${voice.name} (${voice.lang})`;
        option.selected = selected && voice.voiceURI === selected.voiceURI;
        voiceSelect.appendChild(option);
      }
    };
    populateVoices();
    window.speechSynthesis.addEventListener("voiceschanged", populateVoices);
    let attempts = 0;
    const poll = setInterval(() => {
      if (rankedVoices().length || ++attempts > 10) {
        clearInterval(poll);
        populateVoices();
      }
    }, 250);
    if (voiceSelect) {
      voiceSelect.addEventListener("change", () => {
        localStorage.setItem(VOICE_KEY, voiceSelect.value);
        notify();
      });
    }
    if (rateInput) {
      rateInput.value = getSavedRate();
      if (rateOutput) rateOutput.value = `${getSavedRate()}\xD7`;
      rateInput.addEventListener("input", () => {
        const rate = Number(rateInput.value);
        if (rate >= 0.5 && rate <= 2) {
          localStorage.setItem(RATE_KEY, String(rate));
          if (rateOutput) rateOutput.value = `${rate}\xD7`;
          notify();
        }
      });
    }
    if (asidesSelect) {
      asidesSelect.value = getSavedAsideMode();
      asidesSelect.addEventListener("change", () => {
        localStorage.setItem(ASIDES_KEY, asidesSelect.value);
        notify();
      });
    }
    if (autoScrollInput) {
      autoScrollInput.checked = getSavedAutoScroll();
      autoScrollInput.addEventListener("change", () => {
        localStorage.setItem(AUTOSCROLL_KEY, String(autoScrollInput.checked));
        notify();
      });
    }
    if (autoContinueInput) {
      autoContinueInput.checked = getSavedAutoContinue();
      autoContinueInput.addEventListener("change", () => {
        localStorage.setItem(
          AUTOCONTINUE_KEY,
          String(autoContinueInput.checked)
        );
      });
    }
  }

  // ../../js/src/read-aloud/player-ui.js
  var CONTINUE_FLAG = "ptxReadAloudContinue";
  var CONTINUE_AUTO = "auto";
  var AUTOPLAY_GRACE_MS = 3e3;
  var OPEN_HINT_KEY = "readAloudOpenHintShown";
  var OPEN_HINT_LIMIT = 3;
  var INTERACTIVE_SELECTOR = "a, button, input, select, textarea, summary, label, iframe, audio, video, [data-knowl], .knowl__link, .sagecell";
  var ReadAloudPlayer = class {
    constructor(button, player) {
      this.button = button;
      this.player = player;
      this.strings = STRINGS;
      this.content = document.getElementById("ptx-content");
      this.blocks = [];
      this.hasSpoken = false;
      this.highlighter = new Highlighter();
      this.highlighter.autoScroll = getSavedAutoScroll();
      this.queue = new SpeechQueue({
        onUtterance: (i, item) => this._onUtterance(i, item),
        onState: (state) => this._onState(state),
        onEnded: () => this._onEnded(),
        mode: getSavedAsideMode(),
        describeBlock: (blockIndex) => this._describeBlock(blockIndex)
      });
      this.queue.setLang(documentLang());
      initSettingsControls(({ voice, rate, autoScroll, asideMode }) => {
        this.queue.setVoice(voice);
        this.queue.setRate(rate);
        this.queue.setMode(asideMode);
        this.highlighter.autoScroll = autoScroll;
      });
      this._wireControls();
      this._wireSettingsDialog();
      this._wireClickToStart();
      this._wireMediaSession();
    }
    /**
     * The settings dialog, opened from the player's own settings button.
     *
     * These controls used to sit in the readability-options dialog, but they
     * are only meaningful while something is being read, and burying them
     * behind a general typography menu made them hard to find at the moment
     * they mattered.  PTXDialog comes from pretext-core.js, which the XSL
     * always loads first; guard anyway so a missing bundle costs the settings
     * button rather than the whole player.
     */
    _wireSettingsDialog() {
      const popup = document.getElementById("ptx-read-aloud-settings-popup");
      const button = document.getElementById("ptx-read-aloud-settings-button");
      if (!popup || !button || !window.PTXDialog) return;
      this.settingsPopup = popup;
      this.settingsDialog = new window.PTXDialog(popup, button, {
        kind: "light-close",
        closeButton: document.getElementById(
          "ptx-read-aloud-settings-close-button"
        )
      });
    }
    //------------------------------------------------------------------
    // Opening and closing
    open() {
      this.player.hidden = false;
      this._setButtonState(true);
      sessionStorage.removeItem(CONTINUE_FLAG);
    }
    close() {
      this.queue.stop();
      this.highlighter.clear();
      if (this.settingsPopup && this.settingsPopup.open) {
        this.settingsDialog.close();
      }
      const focusWasInside = this.player.contains(document.activeElement);
      this.player.hidden = true;
      this._setButtonState(false);
      if (focusWasInside) this.button.focus();
      if (navigator.mediaSession) {
        navigator.mediaSession.playbackState = "none";
      }
    }
    /**
     * Keep the toolbar button reading as the disclosure toggle it now is.
     *
     * With the player's own close button gone, this button is the only way
     * back, so its tooltip has to name the action rather than the feature —
     * "Read aloud" on a control that hides the read-aloud player is worse
     * than no tooltip at all.
     */
    _setButtonState(open) {
      this.button.setAttribute("aria-expanded", String(open));
      const title = open ? this.strings["read-aloud-hide"] : this.strings["read-aloud-show"];
      if (title) this.button.title = title;
    }
    get isOpen() {
      return !this.player.hidden;
    }
    //------------------------------------------------------------------
    // Playback
    async _ensurePlan() {
      this.blocks = await collect(this.content, { strings: this.strings });
      const plan = buildPlan(this.blocks, {
        locale: documentLang(),
        strings: this.strings
      });
      await whenVoicesReady();
      this.queue.setVoice(getSavedVoice());
      this.queue.setRate(getSavedRate());
      this.queue.setPlan(plan, this.blocks);
    }
    async playFromTop() {
      this.highlighter.resetScrollSuppression();
      this.hasSpoken = false;
      await this._ensurePlan();
      this.queue.playFrom(0);
    }
    /**
     * Start a page that the previous one handed off to via auto-continue.
     *
     * Speech is gated behind user activation in Chrome and Safari, and
     * whether a navigation carries that activation into the new document
     * varies by browser and by how the navigation was made — so this tries,
     * and is built to be refused.  If nothing has actually spoken by the end
     * of the grace period, it drops into exactly the state the manual
     * Continue link produces: player open, play button pulsing, one click
     * away from reading.  The listener is never left in silence with no
     * visible next step.
     */
    async resumeContinuation() {
      await this.playFromTop();
      setTimeout(() => {
        if (this.hasSpoken) return;
        this.queue.stop();
        this.highlighter.clear();
        this.player.dataset.state = "continue-ready";
      }, AUTOPLAY_GRACE_MS);
    }
    async toggle() {
      this.highlighter.resetScrollSuppression();
      if (this.queue.state === "idle" || this.queue.state === "ended") {
        await this.playFromTop();
      } else {
        this.queue.toggle();
      }
    }
    //------------------------------------------------------------------
    // Queue callbacks
    _onUtterance(index, item) {
      this.hasSpoken = true;
      this._reveal(this.blocks[item.blockIndex]);
      this.highlighter.show(item, this.blocks);
    }
    /**
     * Open any collapsed <details> around the block about to be spoken.
     *
     * Collection deliberately reaches inside closed knowls, so playback can
     * arrive somewhere the reader cannot see.  Opening on arrival keeps the
     * page in step with the audio — and the highlighter needs the text
     * rendered to highlight it at all.
     *
     * A title is the exception: reading "Theorem 3.2" is not a reason to
     * expand the theorem, since in skip mode the body is never read and a
     * sighted reader would still be looking at a closed knowl.
     */
    _reveal(block) {
      if (!block || !block.el) return;
      let details = block.el.closest("details");
      if (block.summary && details) {
        details = details.parentElement ? details.parentElement.closest("details") : null;
      }
      while (details) {
        if (!details.open) details.open = true;
        details = details.parentElement ? details.parentElement.closest("details") : null;
      }
    }
    /**
     * What kind of block the arrow keys have landed on, for the spoken
     * announcement.  PreTeXt already renders localized type names into the
     * page — in a knowl's heading and in every permalink's @data-description
     * — so they are read back out of the DOM rather than duplicated as new
     * localization strings that could drift out of step.
     */
    _describeBlock(blockIndex) {
      const block = this.blocks[blockIndex];
      if (!block || !block.el) return null;
      const node = enclosingBlock(this.blocks, blockIndex);
      const name = block.summary ? this._typeName(node) : this._selfName(block) || this._typeName(node);
      if (!name) return null;
      const hint = this._openableAside(blockIndex) ? this._openHint() : null;
      return hint ? `${name} ${hint}` : name;
    }
    /** The type name PreTeXt rendered for a node, e.g. "Theorem", "Proof.". */
    _typeName(node) {
      if (!node || !node.el || !node.el.querySelector) return null;
      const typeSpan = node.el.querySelector(
        ":scope > summary .type, :scope > .heading .type, :scope > h1 .type, :scope > h2 .type, :scope > h3 .type, :scope > h4 .type, :scope > h5 .type, :scope > h6 .type"
      );
      const name = typeSpan && typeSpan.textContent.trim();
      if (name) return name;
      const tooltip = node.el.querySelector(
        ":scope > summary.ptx-footnote__number[title]"
      );
      if (tooltip) {
        const label = tooltip.getAttribute("title").trim();
        if (label) return label;
      }
      return this.strings[node.type] || null;
    }
    /** What a non-title block calls itself, from its own permalink. */
    _selfName(block) {
      if (!block.el.querySelector) return null;
      const permalink = block.el.querySelector(":scope > [data-description]");
      return permalink && permalink.getAttribute("data-description") || null;
    }
    /** The aside this block titles, if it is one and it is still closed. */
    _openableAside(blockIndex) {
      const block = this.blocks[blockIndex];
      if (!block || !block.summary) return null;
      const asides = block.path.filter((n) => n.aside);
      const own = asides[asides.length - 1];
      return own && !this.queue.entered.has(own.el) ? own : null;
    }
    /**
     * "Press space to open", for the first few knowls a reader meets.
     *
     * An audio interface has no affordances to look at, so the only way to
     * learn the key is to be told — but being told every time, on a page with
     * forty knowls, is unbearable.  The count persists across pages so the
     * hint fades over a session rather than restarting with every navigation.
     */
    _openHint() {
      const hint = this.strings["read-aloud-open-hint"];
      if (!hint) return null;
      const shown = Number(localStorage.getItem(OPEN_HINT_KEY)) || 0;
      if (shown >= OPEN_HINT_LIMIT) return null;
      localStorage.setItem(OPEN_HINT_KEY, String(shown + 1));
      return hint;
    }
    _onState(state) {
      this.player.dataset.state = state;
      const toggleButton = document.getElementById("ptx-read-aloud-toggle");
      if (toggleButton) {
        const speaking = state === "speaking";
        toggleButton.title = speaking ? this.strings["read-aloud-pause"] : this.strings["read-aloud-play"];
        toggleButton.setAttribute("aria-pressed", String(speaking));
      }
      if (navigator.mediaSession) {
        navigator.mediaSession.playbackState = state === "speaking" ? "playing" : state === "paused" ? "paused" : "none";
      }
    }
    /** Where the page's own "next" navigation button points, or null. */
    _nextPageHref() {
      const nextLink = document.querySelector(".next-button:not(.disabled)");
      const href = nextLink && nextLink.getAttribute("href");
      return href || null;
    }
    /**
     * May the reading carry itself on to the next page?
     *
     * The setting is necessary but not sufficient.  `hasSpoken` is the guard
     * that matters: an engine that refuses to speak reports an error per
     * utterance, and the queue's own error handling would otherwise reach
     * this same "finished the page" callback in a few milliseconds without a
     * word having been heard.  Auto-continuing from there would do it again
     * on the next page, and the one after — a silent runaway through the
     * whole book.  Requiring that something was actually spoken keeps a
     * refused page from ever handing off.
     */
    _shouldAutoContinue() {
      return getSavedAutoContinue() && this.hasSpoken;
    }
    _onEnded() {
      this.highlighter.clear();
      const href = this._nextPageHref();
      if (!href) return;
      const continueLink = document.getElementById("ptx-read-aloud-continue");
      if (continueLink) {
        continueLink.href = href;
        continueLink.hidden = false;
      }
      if (this._shouldAutoContinue()) {
        sessionStorage.setItem(CONTINUE_FLAG, CONTINUE_AUTO);
        this.queue.speakOnce(this.strings["read-aloud-continuing"], () => {
          window.location.href = href;
        });
      }
    }
    //------------------------------------------------------------------
    // Wiring
    _wireControls() {
      const on = (id, handler) => {
        const el = document.getElementById(id);
        if (el) el.addEventListener("click", handler);
      };
      on("ptx-read-aloud-toggle", () => this.toggle());
      on("ptx-read-aloud-next", () => {
        this.highlighter.resetScrollSuppression();
        this.queue.next();
      });
      on("ptx-read-aloud-prev", () => {
        this.highlighter.resetScrollSuppression();
        this.queue.prev();
      });
      const continueLink = document.getElementById("ptx-read-aloud-continue");
      if (continueLink) {
        continueLink.addEventListener("click", () => {
          sessionStorage.setItem(CONTINUE_FLAG, "true");
        });
      }
      this.player.addEventListener("keydown", (e) => {
        if (e.key === "ArrowRight") {
          e.preventDefault();
          this.queue.next();
        } else if (e.key === "ArrowLeft") {
          e.preventDefault();
          this.queue.prev();
        }
      });
      document.addEventListener("keydown", (e) => {
        if (this.queue.state !== "speaking" && this.queue.state !== "paused") {
          return;
        }
        if (e.altKey || e.ctrlKey || e.metaKey) return;
        if (e.target.closest("input, textarea, select, [contenteditable]")) {
          return;
        }
        if (e.key === "ArrowDown") {
          e.preventDefault();
          this.queue.nextBlock();
        } else if (e.key === "ArrowUp") {
          e.preventDefault();
          this.queue.previousBlock();
        } else if (e.key === " " || e.key === "ArrowRight") {
          if (this.queue.pendingStart) {
            e.preventDefault();
            this.queue.resume();
          }
        }
      });
    }
    _wireClickToStart() {
      if (!this.content) return;
      this.content.addEventListener("click", (e) => {
        if (!this.isOpen) return;
        if (e.target.closest(INTERACTIVE_SELECTOR)) return;
        let blockIndex = -1;
        this.blocks.forEach((b, i) => {
          if (b.el && b.el.contains(e.target)) blockIndex = i;
        });
        if (blockIndex < 0) return;
        const planIndex = this._planIndexForClick(blockIndex, e.target);
        if (planIndex >= 0) {
          this.highlighter.resetScrollSuppression();
          this.queue.playFrom(planIndex);
        }
      });
    }
    /**
     * The utterance a click landed on, falling back to the head of the block.
     *
     * Clicking the fourth sentence of a paragraph should start there, not
     * restart the paragraph, so this matches the clicked text node against
     * the plan's range map (segmenter.js keeps ranges pointing at the
     * original DOM text nodes precisely so this is possible).
     */
    _planIndexForClick(blockIndex, target) {
      const block = this.blocks[blockIndex];
      const fallback = this.queue.indexForBlock(blockIndex);
      if (!block || !target) return fallback;
      const clicked = /* @__PURE__ */ new Set();
      const walk = (el) => {
        for (const child of el.childNodes) {
          if (child.nodeType === Node.TEXT_NODE) clicked.add(child);
          else if (child.nodeType === Node.ELEMENT_NODE) walk(child);
        }
      };
      if (target.nodeType === Node.ELEMENT_NODE) walk(target);
      for (let i = 0; i < this.queue.plan.length; i++) {
        const item = this.queue.plan[i];
        if (item.blockIndex !== blockIndex) continue;
        for (const range of item.ranges) {
          const token = block.tokens[range.tokenIndex];
          if (!token) continue;
          if (token.node && clicked.has(token.node)) return i;
          if (token.el && (token.el === target || token.el.contains(target))) {
            return i;
          }
        }
      }
      return fallback;
    }
    _wireMediaSession() {
      if (!("mediaSession" in navigator)) return;
      try {
        navigator.mediaSession.metadata = new MediaMetadata({
          title: document.title
        });
        navigator.mediaSession.setActionHandler("play", () => this.toggle());
        navigator.mediaSession.setActionHandler("pause", () => this.queue.pause());
        navigator.mediaSession.setActionHandler("previoustrack", () => this.queue.prev());
        navigator.mediaSession.setActionHandler("nexttrack", () => this.queue.next());
      } catch (e) {
      }
    }
  };
  function continuationMode() {
    const flag = sessionStorage.getItem(CONTINUE_FLAG);
    if (flag === CONTINUE_AUTO) return "auto";
    return flag === "true" ? "manual" : null;
  }

  // ../../js/src/read-aloud/index.js
  window.addEventListener("DOMContentLoaded", () => {
    const button = document.getElementById("ptx-read-aloud-button");
    const playerElement = document.getElementById("ptx-read-aloud-player");
    if (!button || !playerElement) return;
    if (!("speechSynthesis" in window)) {
      button.hidden = true;
      return;
    }
    let player = null;
    const ensurePlayer = () => {
      if (!player) {
        player = new ReadAloudPlayer(button, playerElement);
      }
      return player;
    };
    button.addEventListener("click", () => {
      const p = ensurePlayer();
      if (p.isOpen) {
        p.close();
      } else {
        p.open();
      }
    });
    const continuation = continuationMode();
    if (continuation) {
      const p = ensurePlayer();
      p.open();
      playerElement.dataset.state = "continue-ready";
      if (continuation === "auto") p.resumeContinuation();
    }
    window.PTXReadAloud = {
      collect,
      buildPlan,
      sentenceBoundaries,
      SpeechQueue,
      player: ensurePlayer,
      speakPage: () => ensurePlayer().playFromTop(),
      // Reports what MathJax actually produced for each expression, which
      // is the only way to tell a speech-generation problem apart from a
      // read-aloud one: if aria-label is null everywhere, the fault is in
      // MathJax's speech setup, not in this feature.
      debugMath: () => {
        const containers = document.querySelectorAll("mjx-container");
        console.log("MathJax version:", window.MathJax?.version);
        console.log("enableSpeech:", window.MathJax?.config?.options?.enableSpeech);
        console.log("sre options:", window.MathJax?.config?.options?.sre);
        console.log(`${containers.length} typeset expression(s):`);
        const inner = (el, attr) => {
          const node = el.querySelector(`[${attr}]`);
          return node && node.getAttribute(attr);
        };
        containers.forEach((el, i) => {
          console.log(i, {
            resolved: readMathSpeech(el),
            ownAriaLabel: el.getAttribute("aria-label"),
            ownSemanticSpeech: el.getAttribute("data-semantic-speech"),
            ownSpeechNone: el.getAttribute("data-semantic-speech-none"),
            innerAriaLabel: inner(el, "aria-label"),
            innerSemanticSpeech: inner(el, "data-semantic-speech"),
            assistiveMml: !!el.querySelector("mjx-assistive-mml")
          });
        });
      }
    };
  });
})();
//# sourceMappingURL=pretext-read-aloud.js.map
