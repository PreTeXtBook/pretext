"use strict";
/**
 * A javascript module to handle separation of author sourced scripts into
 * IFRAMES. All such scripts will have limited access to the actual document
 * on the VLE side and this script represents the VLE side endpoint for
 * message handling needed to give that access. When porting STACK onto VLEs
 * one needs to map this script to do the following:
 *
 *  1. Ensure that searches for target elements/inputs are limited to questions
 *     and do not return any elements outside them.
 *
 *  2. Map any identifiers needed to identify inputs by name.
 *
 *  3. Any change handling related to input value modifications through this
 *     logic gets connected to any such handling on the VLE side.
 *
 *
 * This script is intenttionally ordered so that the VLE specific bits should
 * be at the top.
 *
 *
 * This script assumes the following:
 *
 *  1. Each relevant IFRAME has an `id`-attribute that will be told to this
 *     script.
 *
 *  2. Each such IFRAME exists within the question itself, so that one can
 *     traverse up the DOM tree from that IFRAME to find the border of
 *     the question.
 *
 * @module     qtype_stack/stackjsvle
 * @copyright  2023 Aalto University
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */
let IFRAMES = {};
let INPUTS = {};
let INPUTS_INPUT_EVENT = {};
let DISABLE_CHANGES = false;
function vle_get_element(id) {
  let candidate = document.getElementById(id);
  let iter = candidate;
  while (iter && !iter.classList.contains("formulation")) {
    iter = iter.parentElement;
  }
  if (iter && iter.classList.contains("formulation")) {
    return candidate;
  }
  return null;
}
function vle_get_input_element(name, srciframe) {
  let initialcandidate = document.getElementById(srciframe);
  let iter = initialcandidate;
  while (iter && !iter.classList.contains("formulation")) {
    iter = iter.parentElement;
  }
  if (iter && iter.classList.contains("formulation")) {
    let possible2 = iter.querySelector('input[id$="_' + name + '"]');
    if (possible2 !== null) {
      return possible2;
    }
    possible2 = iter.querySelector('input[id$="_' + name + '_1"][type=radio]');
    if (possible2 !== null) {
      return possible2;
    }
    possible2 = iter.querySelector('select[id$="_' + name + '"]');
    if (possible2 !== null) {
      return possible2;
    }
  }
  let possible = document.querySelector('.formulation input[id$="_' + name + '"]');
  if (possible !== null) {
    return possible;
  }
  possible = document.querySelector('.formulation input[id$="_' + name + '_1"][type=radio]');
  if (possible !== null) {
    return possible;
  }
  possible = document.querySelector('.formulation select[id$="_' + name + '"]');
  return possible;
}
function vle_update_input(inputelement) {
  const c = new Event("change");
  inputelement.dispatchEvent(c);
  const i = new Event("input");
  inputelement.dispatchEvent(i);
}
function vle_update_dom(modifiedsubtreerootelement) {
  CustomEvents.notifyFilterContentUpdated(modifiedsubtreerootelement);
}
function vle_html_sanitize(src) {
  let parser = new DOMParser();
  let doc = parser.parseFromString(src, "text/html");
  for (let el of doc.querySelectorAll("script, style")) {
    el.remove();
  }
  for (let el of doc.querySelectorAll("*")) {
    for (let { name, value } of el.attributes) {
      if (is_evil_attribute(name, value)) {
        el.removeAttribute(name);
      }
    }
  }
  return doc.body;
}
function is_evil_attribute(name, value) {
  const lcname = name.toLowerCase();
  if (lcname.startsWith("on")) {
    return true;
  }
  if (lcname === "src" || lcname.endsWith("href")) {
    const lcvalue = value.replace(/\s+/g, "").toLowerCase();
    if (lcvalue.includes("javascript:") || lcvalue.includes("data:text")) {
      return true;
    }
  }
  return false;
}
window.addEventListener("message", (e) => {
  if (!(typeof e.data === "string" || e.data instanceof String)) {
    return;
  }
  let msg = null;
  try {
    msg = JSON.parse(e.data);
  } catch (e2) {
    return;
  }
  if (!("version" in msg && msg.version.startsWith("STACK-JS"))) {
    return;
  }
  if (!("src" in msg && "type" in msg && msg.src in IFRAMES)) {
    return;
  }
  let element = null;
  let input = null;
  let response = {
    version: "STACK-JS:1.1.0"
  };
  switch (msg.type) {
    case "register-input-listener":
      input = vle_get_input_element(msg.name, msg.src);
      if (input === null) {
        response.type = "error";
        response.msg = 'Failed to connect to input: "' + msg.name + '"';
        response.tgt = msg.src;
        IFRAMES[msg.src].contentWindow.postMessage(JSON.stringify(response), "*");
        return;
      }
      response.type = "initial-input";
      response.name = msg.name;
      response.tgt = msg.src;
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
        for (let inp of document.querySelectorAll("input[type=radio][name=" + CSS.escape(input.name) + "]")) {
          if (inp.checked) {
            response.value = inp.value;
          }
        }
      }
      if (input.id in INPUTS) {
        if (msg.src in INPUTS[input.id]) {
          return;
        }
        if (input.type !== "radio") {
          INPUTS[input.id].push(msg.src);
        } else {
          let radgroup = document.querySelectorAll("input[type=radio][name=" + CSS.escape(input.name) + "]");
          for (let inp of radgroup) {
            INPUTS[inp.id].push(msg.src);
          }
        }
      } else {
        if (input.type !== "radio") {
          INPUTS[input.id] = [msg.src];
        } else {
          let radgroup = document.querySelectorAll("input[type=radio][name=" + CSS.escape(input.name) + "]");
          for (let inp of radgroup) {
            INPUTS[inp.id] = [msg.src];
          }
        }
        if (input.type !== "radio") {
          input.addEventListener("change", () => {
            if (DISABLE_CHANGES) {
              return;
            }
            let resp = {
              version: "STACK-JS:1.0.0",
              type: "changed-input",
              name: msg.name
            };
            if (input.type === "checkbox") {
              resp["value"] = input.checked;
            } else {
              resp["value"] = input.value;
            }
            for (let tgt of INPUTS[input.id]) {
              resp["tgt"] = tgt;
              IFRAMES[tgt].contentWindow.postMessage(JSON.stringify(resp), "*");
            }
          });
        } else {
          let radgroup = document.querySelectorAll("input[type=radio][name=" + CSS.escape(input.name) + "]");
          radgroup.forEach((inp) => {
            inp.addEventListener("change", () => {
              if (DISABLE_CHANGES) {
                return;
              }
              let resp = {
                version: "STACK-JS:1.0.0",
                type: "changed-input",
                name: msg.name
              };
              if (inp.checked) {
                resp.value = inp.value;
              } else {
                return;
              }
              for (let tgt of INPUTS[inp.id]) {
                resp["tgt"] = tgt;
                IFRAMES[tgt].contentWindow.postMessage(JSON.stringify(resp), "*");
              }
            });
          });
        }
      }
      if ("track-input" in msg && msg["track-input"] && input.type !== "radio") {
        if (input.id in INPUTS_INPUT_EVENT) {
          if (msg.src in INPUTS_INPUT_EVENT[input.id]) {
            return;
          }
          INPUTS_INPUT_EVENT[input.id].push(msg.src);
        } else {
          INPUTS_INPUT_EVENT[input.id] = [msg.src];
          input.addEventListener("input", () => {
            if (DISABLE_CHANGES) {
              return;
            }
            let resp = {
              version: "STACK-JS:1.0.0",
              type: "changed-input",
              name: msg.name
            };
            if (input.type === "checkbox") {
              resp["value"] = input.checked;
            } else {
              resp["value"] = input.value;
            }
            for (let tgt of INPUTS_INPUT_EVENT[input.id]) {
              resp["tgt"] = tgt;
              IFRAMES[tgt].contentWindow.postMessage(JSON.stringify(resp), "*");
            }
          });
        }
      }
      if (!(msg.src in INPUTS[input.id])) {
        IFRAMES[msg.src].contentWindow.postMessage(JSON.stringify(response), "*");
      }
      break;
    case "changed-input":
      input = vle_get_input_element(msg.name, msg.src);
      if (input === null) {
        const ret = {
          version: "STACK-JS:1.0.0",
          type: "error",
          msg: 'Failed to modify input: "' + msg.name + '"',
          tgt: msg.src
        };
        IFRAMES[msg.src].contentWindow.postMessage(JSON.stringify(ret), "*");
        return;
      }
      DISABLE_CHANGES = true;
      if (input.type === "checkbox") {
        input.checked = msg.value;
      } else {
        input.value = msg.value;
      }
      vle_update_input(input);
      DISABLE_CHANGES = false;
      response.type = "changed-input";
      response.name = msg.name;
      response.value = msg.value;
      for (let tgt of INPUTS[input.id]) {
        if (tgt !== msg.src) {
          response.tgt = tgt;
          IFRAMES[tgt].contentWindow.postMessage(JSON.stringify(response), "*");
        }
      }
      break;
    case "toggle-visibility":
      element = vle_get_element(msg.target);
      if (element === null) {
        const ret = {
          version: "STACK-JS:1.0.0",
          type: "error",
          msg: 'Failed to find element: "' + msg.target + '"',
          tgt: msg.src
        };
        IFRAMES[msg.src].contentWindow.postMessage(JSON.stringify(ret), "*");
        return;
      }
      if (msg.set === "show") {
        element.style.display = "block";
        vle_update_dom(element);
      } else if (msg.set === "hide") {
        element.style.display = "none";
      }
      break;
    case "change-content":
      element = vle_get_element(msg.target);
      if (element === null) {
        response.type = "error";
        response.msg = 'Failed to find element: "' + msg.target + '"';
        response.tgt = msg.src;
        IFRAMES[msg.src].contentWindow.postMessage(JSON.stringify(response), "*");
        return;
      }
      element.replaceChildren(vle_html_sanitize(msg.content));
      vle_update_dom(element);
      break;
    case "get-content":
      element = vle_get_element(msg.target);
      response.type = "xfer-content";
      response.tgt = msg.src;
      response.target = msg.target;
      response.content = null;
      if (element !== null) {
        response.content = element.innerHTML;
      }
      IFRAMES[msg.src].contentWindow.postMessage(JSON.stringify(response), "*");
      break;
    case "resize-frame":
      element = IFRAMES[msg.src].parentElement;
      element.style.width = msg.width;
      element.style.height = msg.height;
      IFRAMES[msg.src].style.width = "100%";
      IFRAMES[msg.src].style.height = "100%";
      vle_update_dom(element);
      break;
    case "ping":
      response.type = "ping";
      response.tgt = msg.src;
      IFRAMES[msg.src].contentWindow.postMessage(JSON.stringify(response), "*");
      return;
    case "initial-input":
    case "error":
      break;
    default:
      response.type = "error";
      response.msg = 'Unknown message-type: "' + msg.type + '"';
      response.tgt = msg.src;
      IFRAMES[msg.src].contentWindow.postMessage(JSON.stringify(response), "*");
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
  document.getElementById(targetdivid).replaceChildren(frm);
  IFRAMES[iframeid] = frm;
}
;
//# sourceMappingURL=stackjsvle.js.map
