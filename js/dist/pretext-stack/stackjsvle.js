"use strict";
/**
 * stackjsvle.js — PreTeXt port of the STACK iframe VLE communication layer.
 *
 * Differences from the Moodle version:
 * 1. Iframe/input registries are per-question (keyed by boundary id) instead
 *    of global, so multiple STACK questions on one page don't clash.
 * 2. vle_get_question_boundary() looks for our "_boundary" id instead of
 *    Moodle's .formulation class.
 * 3. vle_get_input_element() matches stackapi_input_{name}, scoped to the
 *    question boundary.
 * 4. vle_update_dom() uses MathJax.typesetPromise() instead of Moodle's
 *    notifyFilterContentUpdated().
 * 5. vle_reset_question_registry() clears old registry state before a
 *    question re-renders, so reused iframe/input ids don't get treated as
 *    "already registered" and silently drop their response.
 * 6. Incoming postMessage senders are identified via e.source (the actual
 *    window that sent the message) instead of the API-supplied msg.src: the
 *    STACK API restarts iframe-id numbering on every render/validate/grade
 *    call, so msg.src can collide between two different questions' iframes
 *    on a multi-question page.
 *
 * @copyright  2023 Aalto University
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */
const QUESTION_IFRAMES = {};
const QUESTION_INPUTS = {};
const QUESTION_INPUTS_INPUT_EVENT = {};
const IFRAME_TO_BOUNDARY = {};
const IFRAME_RAW_ID = {};
const WINDOW_TO_KEY = /* @__PURE__ */ new WeakMap();
let iframeKeySeq = 0;
let IFRAMES = {};
let DISABLE_CHANGES = false;
function getQuestionRegistry(boundaryId) {
  if (!QUESTION_IFRAMES[boundaryId]) {
    QUESTION_IFRAMES[boundaryId] = {};
    QUESTION_INPUTS[boundaryId] = {};
    QUESTION_INPUTS_INPUT_EVENT[boundaryId] = {};
  }
  return {
    iframes: QUESTION_IFRAMES[boundaryId],
    inputs: QUESTION_INPUTS[boundaryId],
    inputsInputEvent: QUESTION_INPUTS_INPUT_EVENT[boundaryId]
  };
}
function vle_reset_question_registry(boundaryId) {
  if (QUESTION_IFRAMES[boundaryId]) {
    for (const key of Object.keys(QUESTION_IFRAMES[boundaryId])) {
      delete IFRAMES[key];
      delete IFRAME_TO_BOUNDARY[key];
      delete IFRAME_RAW_ID[key];
    }
  }
  QUESTION_IFRAMES[boundaryId] = {};
  QUESTION_INPUTS[boundaryId] = {};
  QUESTION_INPUTS_INPUT_EVENT[boundaryId] = {};
}
function vle_get_question_boundary(element) {
  let iter = element;
  while (iter) {
    if (iter.id && iter.id.endsWith("_boundary")) {
      return iter;
    }
    if (iter.classList) {
      if (iter.classList.contains("formulation")) return iter;
      if (iter.classList.contains("que") && iter.classList.contains("stack")) return iter;
    }
    iter = iter.parentElement;
  }
  return null;
}
function vle_get_element(id) {
  return document.getElementById(id);
}
function vle_get_input_element(name, srciframe) {
  const boundaryId = IFRAME_TO_BOUNDARY[srciframe];
  let scope = document;
  if (boundaryId) {
    const boundary = document.getElementById(boundaryId);
    if (boundary) scope = boundary;
  }
  let possible = scope.querySelector(`input[name="stackapi_input_${name}"]`);
  if (possible) return possible;
  possible = scope.querySelector(`textarea[name="stackapi_input_${name}"]`);
  if (possible) return possible;
  possible = scope.querySelector(`select[name="stackapi_input_${name}"]`);
  if (possible) return possible;
  possible = scope.querySelector(`input[name$="_${name}"]`);
  if (possible && possible.type !== "radio") return possible;
  possible = scope.querySelector(`input[name$="_${name}"][type=radio]`);
  if (possible) return possible;
  possible = scope.querySelector(`select[name$="_${name}"]`);
  if (possible) return possible;
  if (scope !== document) {
    possible = document.querySelector(`input[name="stackapi_input_${name}"]`);
    if (possible) return possible;
    possible = document.querySelector(`textarea[name="stackapi_input_${name}"]`);
    if (possible) return possible;
  }
  return null;
}
function vle_update_input(inputelement) {
  inputelement.dispatchEvent(new Event("change"));
  inputelement.dispatchEvent(new Event("input"));
}
function vle_update_dom(modifiedsubtreerootelement) {
  if (window.MathJax && MathJax.typesetPromise) {
    MathJax.typesetPromise([modifiedsubtreerootelement]).catch((err) => console.log("MathJax error in vle_update_dom:", err.message));
  } else if (window.MathJax && MathJax.typeset) {
    MathJax.typeset([modifiedsubtreerootelement]);
  }
}
function vle_html_sanitize(src) {
  const parser = new DOMParser();
  const doc = parser.parseFromString(src, "text/html");
  for (const el of doc.querySelectorAll("script, style")) el.remove();
  for (const el of doc.querySelectorAll("*")) {
    for (const { name, value } of el.attributes) {
      if (is_evil_attribute(name, value)) el.removeAttribute(name);
    }
  }
  return doc.body;
}
function is_evil_attribute(name, value) {
  const lcname = name.toLowerCase();
  if (lcname.startsWith("on")) return true;
  if (lcname === "src" || lcname.endsWith("href")) {
    const lcvalue = value.replace(/\s+/g, "").toLowerCase();
    if (lcvalue.includes("javascript:") || lcvalue.includes("data:text")) return true;
  }
  return false;
}
window.addEventListener("message", (e) => {
  if (!(typeof e.data === "string" || e.data instanceof String)) return;
  let msg = null;
  try {
    msg = JSON.parse(e.data);
  } catch (e2) {
    return;
  }
  if (!("version" in msg && msg.version.startsWith("STACK-JS"))) return;
  if (!("src" in msg && "type" in msg)) return;
  const key = WINDOW_TO_KEY.get(e.source);
  if (key === void 0) return;
  const boundaryId = IFRAME_TO_BOUNDARY[key];
  if (boundaryId) getQuestionRegistry(boundaryId);
  const Q_INPUTS = QUESTION_INPUTS[boundaryId] || {};
  const Q_INPUTS_INPUT_EVENT = QUESTION_INPUTS_INPUT_EVENT[boundaryId] || {};
  let element = null;
  let input = null;
  const response = { version: "STACK-JS:1.1.0" };
  switch (msg.type) {
    case "register-input-listener":
      input = vle_get_input_element(msg.name, key);
      if (input === null) {
        response.type = "error";
        response.msg = 'Failed to connect to input: "' + msg.name + '"';
        response.tgt = IFRAME_RAW_ID[key];
        e.source.postMessage(JSON.stringify(response), "*");
        return;
      }
      response.type = "initial-input";
      response.name = msg.name;
      response.tgt = IFRAME_RAW_ID[key];
      if (input.nodeName.toLowerCase() === "select") {
        response.value = input.value;
        response["input-type"] = "select";
        response["input-readonly"] = input.hasAttribute("disabled");
      } else if (input.type === "checkbox") {
        response.value = input.checked;
        response["input-type"] = "checkbox";
        response["input-readonly"] = input.hasAttribute("disabled");
      } else {
        response.value = input.value;
        response["input-type"] = input.type;
        response["input-readonly"] = input.hasAttribute("readonly");
      }
      if (input.type === "radio") {
        response["input-readonly"] = input.hasAttribute("disabled");
        response.value = "";
        for (const inp of document.querySelectorAll("input[type=radio][name=" + CSS.escape(input.name) + "]")) {
          if (inp.checked) response.value = inp.value;
        }
      }
      if (input.id in Q_INPUTS) {
        if (!Q_INPUTS[input.id].includes(key)) {
          if (input.type !== "radio") {
            Q_INPUTS[input.id].push(key);
          } else {
            for (const inp of document.querySelectorAll("input[type=radio][name=" + CSS.escape(input.name) + "]")) {
              if (!(inp.id in Q_INPUTS)) Q_INPUTS[inp.id] = [];
              if (!Q_INPUTS[inp.id].includes(key)) Q_INPUTS[inp.id].push(key);
            }
          }
        }
        e.source.postMessage(JSON.stringify(response), "*");
      } else {
        if (input.type !== "radio") {
          Q_INPUTS[input.id] = [key];
          input.addEventListener("change", () => {
            if (DISABLE_CHANGES) return;
            const resp = { version: "STACK-JS:1.0.0", type: "changed-input", name: msg.name };
            resp["value"] = input.type === "checkbox" ? input.checked : input.value;
            for (const tgt of Q_INPUTS[input.id]) {
              resp["tgt"] = IFRAME_RAW_ID[tgt];
              if (IFRAMES[tgt]) IFRAMES[tgt].contentWindow.postMessage(JSON.stringify(resp), "*");
            }
          });
        } else {
          const radgroup = document.querySelectorAll("input[type=radio][name=" + CSS.escape(input.name) + "]");
          for (const inp of radgroup) Q_INPUTS[inp.id] = [key];
          radgroup.forEach((inp) => {
            inp.addEventListener("change", () => {
              if (DISABLE_CHANGES || !inp.checked) return;
              const resp = { version: "STACK-JS:1.0.0", type: "changed-input", name: msg.name, value: inp.value };
              for (const tgt of Q_INPUTS[inp.id]) {
                resp["tgt"] = IFRAME_RAW_ID[tgt];
                if (IFRAMES[tgt]) IFRAMES[tgt].contentWindow.postMessage(JSON.stringify(resp), "*");
              }
            });
          });
        }
        if ("track-input" in msg && msg["track-input"] && input.type !== "radio") {
          if (input.id in Q_INPUTS_INPUT_EVENT) {
            if (!Q_INPUTS_INPUT_EVENT[input.id].includes(key)) {
              Q_INPUTS_INPUT_EVENT[input.id].push(key);
            }
          } else {
            Q_INPUTS_INPUT_EVENT[input.id] = [key];
            input.addEventListener("input", () => {
              if (DISABLE_CHANGES) return;
              const resp = { version: "STACK-JS:1.0.0", type: "changed-input", name: msg.name };
              resp["value"] = input.type === "checkbox" ? input.checked : input.value;
              for (const tgt of Q_INPUTS_INPUT_EVENT[input.id]) {
                resp["tgt"] = IFRAME_RAW_ID[tgt];
                if (IFRAMES[tgt]) IFRAMES[tgt].contentWindow.postMessage(JSON.stringify(resp), "*");
              }
            });
          }
        }
        e.source.postMessage(JSON.stringify(response), "*");
      }
      break;
    case "changed-input":
      input = vle_get_input_element(msg.name, key);
      if (input === null) {
        e.source.postMessage(JSON.stringify({
          version: "STACK-JS:1.0.0",
          type: "error",
          msg: 'Failed to modify input: "' + msg.name + '"',
          tgt: IFRAME_RAW_ID[key]
        }), "*");
        return;
      }
      DISABLE_CHANGES = true;
      if (input.type === "checkbox") input.checked = msg.value;
      else input.value = msg.value;
      vle_update_input(input);
      DISABLE_CHANGES = false;
      response.type = "changed-input";
      response.name = msg.name;
      response.value = msg.value;
      if (Q_INPUTS[input.id]) {
        for (const tgt of Q_INPUTS[input.id]) {
          if (tgt !== key && IFRAMES[tgt]) {
            response.tgt = IFRAME_RAW_ID[tgt];
            IFRAMES[tgt].contentWindow.postMessage(JSON.stringify(response), "*");
          }
        }
      }
      break;
    case "toggle-visibility":
      element = vle_get_element(msg.target);
      if (element === null) {
        e.source.postMessage(JSON.stringify({
          version: "STACK-JS:1.0.0",
          type: "error",
          msg: 'Failed to find element: "' + msg.target + '"',
          tgt: IFRAME_RAW_ID[key]
        }), "*");
        return;
      }
      if (msg.set === "show") {
        element.style.display = "block";
        vle_update_dom(element);
      } else if (msg.set === "hide") element.style.display = "none";
      break;
    case "change-content":
      element = vle_get_element(msg.target);
      if (element === null) {
        response.type = "error";
        response.msg = 'Failed to find element: "' + msg.target + '"';
        response.tgt = IFRAME_RAW_ID[key];
        e.source.postMessage(JSON.stringify(response), "*");
        return;
      }
      element.replaceChildren(vle_html_sanitize(msg.content));
      vle_update_dom(element);
      break;
    case "get-content":
      element = vle_get_element(msg.target);
      response.type = "xfer-content";
      response.tgt = IFRAME_RAW_ID[key];
      response.target = msg.target;
      response.content = element ? element.innerHTML : null;
      e.source.postMessage(JSON.stringify(response), "*");
      break;
    case "resize-frame":
      element = IFRAMES[key].parentElement;
      element.style.width = msg.width;
      element.style.height = msg.height;
      IFRAMES[key].style.width = "100%";
      IFRAMES[key].style.height = "100%";
      vle_update_dom(element);
      break;
    case "ping":
      response.type = "ping";
      response.tgt = IFRAME_RAW_ID[key];
      e.source.postMessage(JSON.stringify(response), "*");
      return;
    case "initial-input":
    case "error":
      break;
    default:
      response.type = "error";
      response.msg = 'Unknown message-type: "' + msg.type + '"';
      response.tgt = IFRAME_RAW_ID[key];
      e.source.postMessage(JSON.stringify(response), "*");
  }
});
function create_iframe(iframeid, content, targetdivid, title, scrolling, evil) {
  const frm = document.createElement("iframe");
  frm.id = iframeid;
  frm.style.width = "100%";
  frm.style.height = "100%";
  frm.style.border = 0;
  if (scrolling === false) {
    frm.scrolling = "no";
    frm.style.overflow = "hidden";
  } else {
    frm.scrolling = "yes";
  }
  frm.title = title;
  frm.referrerpolicy = "no-referrer";
  if (!evil) {
    frm.sandbox = "allow-scripts allow-downloads";
  }
  frm.srcdoc = content;
  const targetDiv = document.getElementById(targetdivid);
  targetDiv.replaceChildren(frm);
  const key = "iframe-" + iframeKeySeq++;
  IFRAMES[key] = frm;
  IFRAME_RAW_ID[key] = iframeid;
  WINDOW_TO_KEY.set(frm.contentWindow, key);
  const boundary = vle_get_question_boundary(targetDiv);
  if (boundary && boundary.id) {
    IFRAME_TO_BOUNDARY[key] = boundary.id;
    const reg = getQuestionRegistry(boundary.id);
    reg.iframes[key] = frm;
  }
}
//# sourceMappingURL=stackjsvle.js.map
