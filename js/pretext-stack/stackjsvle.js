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
 * 6. create_iframe() adds allow-same-origin to the sandbox for trusted
 *    (non-evil) iframes, so <base href> actually governs relative URLs
 *    fetched from inside the iframe.
 *
 * @copyright  2023 Aalto University
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

'use strict';

// registries, one set of entries per question boundary id
const QUESTION_IFRAMES = {};
const QUESTION_INPUTS = {};
const QUESTION_INPUTS_INPUT_EVENT = {};
const IFRAME_TO_BOUNDARY = {}; // iframe id -> which question it belongs to

let IFRAMES = {}; // flat lookup, all iframes regardless of question

let DISABLE_CHANGES = false; // guards against echoing changes back to sender

function getQuestionRegistry(boundaryId) {
    // create empty registry entries the first time we see this question
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

// wipe a question's registry before re-rendering it (e.g. "new example
// question" button) so stale iframe/input ids don't block re-registration
function vle_reset_question_registry(boundaryId) {
    if (QUESTION_IFRAMES[boundaryId]) {
        for (const iframeId of Object.keys(QUESTION_IFRAMES[boundaryId])) {
            delete IFRAMES[iframeId];
            delete IFRAME_TO_BOUNDARY[iframeId];
        }
    }
    QUESTION_IFRAMES[boundaryId] = {};
    QUESTION_INPUTS[boundaryId] = {};
    QUESTION_INPUTS_INPUT_EVENT[boundaryId] = {};
}

// walk up the DOM from an element to find its enclosing question container
function vle_get_question_boundary(element) {
    let iter = element;
    while (iter) {
        if (iter.id && iter.id.endsWith('_boundary')) {
            return iter;
        }
        if (iter.classList) {
            if (iter.classList.contains('formulation')) return iter;
            if (iter.classList.contains('que') && iter.classList.contains('stack')) return iter;
        }
        iter = iter.parentElement;
    }
    return null;
}

function vle_get_element(id) {
    return document.getElementById(id);
}

// find the actual input/textarea/select for a STACK input name, scoped to
// the question that owns srciframe so two questions can't see each other's inputs
function vle_get_input_element(name, srciframe) {
    const boundaryId = IFRAME_TO_BOUNDARY[srciframe];
    let scope = document;
    if (boundaryId) {
        const boundary = document.getElementById(boundaryId);
        if (boundary) scope = boundary;
    }

    // try exact match first
    let possible = scope.querySelector(`input[name="stackapi_input_${name}"]`);
    if (possible) return possible;
    possible = scope.querySelector(`textarea[name="stackapi_input_${name}"]`);
    if (possible) return possible;
    possible = scope.querySelector(`select[name="stackapi_input_${name}"]`);
    if (possible) return possible;

    // fall back to suffix match (covers _val variants etc.)
    possible = scope.querySelector(`input[name$="_${name}"]`);
    if (possible && possible.type !== 'radio') return possible;
    possible = scope.querySelector(`input[name$="_${name}"][type=radio]`);
    if (possible) return possible;
    possible = scope.querySelector(`select[name$="_${name}"]`);
    if (possible) return possible;

    // last resort: search the whole page if the scoped search failed
    if (scope !== document) {
        possible = document.querySelector(`input[name="stackapi_input_${name}"]`);
        if (possible) return possible;
        possible = document.querySelector(`textarea[name="stackapi_input_${name}"]`);
        if (possible) return possible;
    }

    return null;
}

function vle_update_input(inputelement) {
    // fire both events so anything listening for either still works
    inputelement.dispatchEvent(new Event('change'));
    inputelement.dispatchEvent(new Event('input'));
}

// re-typeset maths after we've changed something in the DOM
function vle_update_dom(modifiedsubtreerootelement) {
    if (window.MathJax && MathJax.typesetPromise) {
        MathJax.typesetPromise([modifiedsubtreerootelement])
            .catch(err => console.log('MathJax error in vle_update_dom:', err.message));
    } else if (window.MathJax && MathJax.typeset) {
        MathJax.typeset([modifiedsubtreerootelement]);
    }
}

// strip scripts/styles and any dangerous attributes before inserting
// iframe-supplied HTML into the page
function vle_html_sanitize(src) {
    const parser = new DOMParser();
    const doc = parser.parseFromString(src, "text/html");
    for (const el of doc.querySelectorAll('script, style')) el.remove();
    for (const el of doc.querySelectorAll('*')) {
        for (const {name, value} of el.attributes) {
            if (is_evil_attribute(name, value)) el.removeAttribute(name);
        }
    }
    return doc.body;
}

function is_evil_attribute(name, value) {
    const lcname = name.toLowerCase();
    if (lcname.startsWith('on')) return true; // inline event handlers
    if (lcname === 'src' || lcname.endsWith('href')) {
        const lcvalue = value.replace(/\s+/g, '').toLowerCase();
        if (lcvalue.includes('javascript:') || lcvalue.includes('data:text')) return true;
    }
    return false;
}

// postMessage handling — this is how the STACK-JS iframes talk to us

window.addEventListener("message", (e) => {
    if (!(typeof e.data === 'string' || e.data instanceof String)) return;

    let msg = null;
    try { msg = JSON.parse(e.data); } catch (e) { return; }

    // ignore anything that isn't a STACK-JS message from a known iframe
    if (!(('version' in msg) && msg.version.startsWith('STACK-JS'))) return;
    if (!(('src' in msg) && ('type' in msg) && (msg.src in IFRAMES))) return;

    const boundaryId = IFRAME_TO_BOUNDARY[msg.src];
    if (boundaryId) getQuestionRegistry(boundaryId);
    const Q_IFRAMES = QUESTION_IFRAMES[boundaryId] || IFRAMES;
    const Q_INPUTS = QUESTION_INPUTS[boundaryId] || {};
    const Q_INPUTS_INPUT_EVENT = QUESTION_INPUTS_INPUT_EVENT[boundaryId] || {};

    let element = null;
    let input = null;
    const response = { version: 'STACK-JS:1.1.0' };

    switch (msg.type) {
    case 'register-input-listener':
        // iframe wants to bind to a real input on the page
        input = vle_get_input_element(msg.name, msg.src);
        if (input === null) {
            response.type = 'error';
            response.msg = 'Failed to connect to input: "' + msg.name + '"';
            response.tgt = msg.src;
            IFRAMES[msg.src].contentWindow.postMessage(JSON.stringify(response), '*');
            return;
        }

        response.type = 'initial-input';
        response.name = msg.name;
        response.tgt = msg.src;

        // report current value back, format depends on input type
        if (input.nodeName.toLowerCase() === 'select') {
            response.value = input.value;
            response['input-type'] = 'select';
            response['input-readonly'] = input.hasAttribute('disabled');
        } else if (input.type === 'checkbox') {
            response.value = input.checked;
            response['input-type'] = 'checkbox';
            response['input-readonly'] = input.hasAttribute('disabled');
        } else {
            response.value = input.value;
            response['input-type'] = input.type;
            response['input-readonly'] = input.hasAttribute('readonly');
        }
        if (input.type === 'radio') {
            // radio groups need the checked option, not just this one element
            response['input-readonly'] = input.hasAttribute('disabled');
            response.value = '';
            for (const inp of document.querySelectorAll('input[type=radio][name=' + CSS.escape(input.name) + ']')) {
                if (inp.checked) response.value = inp.value;
            }
        }

        if (input.id in Q_INPUTS) {
            // already tracking this input, just add this iframe as a listener
            if (!Q_INPUTS[input.id].includes(msg.src)) {
                if (input.type !== 'radio') {
                    Q_INPUTS[input.id].push(msg.src);
                } else {
                    for (const inp of document.querySelectorAll('input[type=radio][name=' + CSS.escape(input.name) + ']')) {
                        if (!(inp.id in Q_INPUTS)) Q_INPUTS[inp.id] = [];
                        if (!Q_INPUTS[inp.id].includes(msg.src)) Q_INPUTS[inp.id].push(msg.src);
                    }
                }
            }
            IFRAMES[msg.src].contentWindow.postMessage(JSON.stringify(response), '*');
        } else {
            // first time seeing this input — wire up change listeners
            if (input.type !== 'radio') {
                Q_INPUTS[input.id] = [msg.src];
                input.addEventListener('change', () => {
                    if (DISABLE_CHANGES) return;
                    const resp = { version: 'STACK-JS:1.0.0', type: 'changed-input', name: msg.name };
                    resp['value'] = input.type === 'checkbox' ? input.checked : input.value;
                    for (const tgt of Q_INPUTS[input.id]) {
                        resp['tgt'] = tgt;
                        if (IFRAMES[tgt]) IFRAMES[tgt].contentWindow.postMessage(JSON.stringify(resp), '*');
                    }
                });
            } else {
                // radios: bind every option in the group together
                const radgroup = document.querySelectorAll('input[type=radio][name=' + CSS.escape(input.name) + ']');
                for (const inp of radgroup) Q_INPUTS[inp.id] = [msg.src];
                radgroup.forEach(inp => {
                    inp.addEventListener('change', () => {
                        if (DISABLE_CHANGES || !inp.checked) return;
                        const resp = { version: 'STACK-JS:1.0.0', type: 'changed-input', name: msg.name, value: inp.value };
                        for (const tgt of Q_INPUTS[inp.id]) {
                            resp['tgt'] = tgt;
                            if (IFRAMES[tgt]) IFRAMES[tgt].contentWindow.postMessage(JSON.stringify(resp), '*');
                        }
                    });
                });
            }

            // optionally also track every keystroke, not just on blur/change
            if (('track-input' in msg) && msg['track-input'] && input.type !== 'radio') {
                if (input.id in Q_INPUTS_INPUT_EVENT) {
                    if (!Q_INPUTS_INPUT_EVENT[input.id].includes(msg.src)) {
                        Q_INPUTS_INPUT_EVENT[input.id].push(msg.src);
                    }
                } else {
                    Q_INPUTS_INPUT_EVENT[input.id] = [msg.src];
                    input.addEventListener('input', () => {
                        if (DISABLE_CHANGES) return;
                        const resp = { version: 'STACK-JS:1.0.0', type: 'changed-input', name: msg.name };
                        resp['value'] = input.type === 'checkbox' ? input.checked : input.value;
                        for (const tgt of Q_INPUTS_INPUT_EVENT[input.id]) {
                            resp['tgt'] = tgt;
                            if (IFRAMES[tgt]) IFRAMES[tgt].contentWindow.postMessage(JSON.stringify(resp), '*');
                        }
                    });
                }
            }

            IFRAMES[msg.src].contentWindow.postMessage(JSON.stringify(response), '*');
        }
        break;

    case 'changed-input':
        // iframe wants to push a new value into a real input on the page
        input = vle_get_input_element(msg.name, msg.src);
        if (input === null) {
            IFRAMES[msg.src].contentWindow.postMessage(JSON.stringify({
                version: 'STACK-JS:1.0.0', type: 'error',
                msg: 'Failed to modify input: "' + msg.name + '"', tgt: msg.src
            }), '*');
            return;
        }
        DISABLE_CHANGES = true; // stop our own listener echoing this straight back
        if (input.type === 'checkbox') input.checked = msg.value;
        else input.value = msg.value;
        vle_update_input(input);
        DISABLE_CHANGES = false;

        // tell every other iframe watching this input about the new value
        response.type = 'changed-input';
        response.name = msg.name;
        response.value = msg.value;
        if (Q_INPUTS[input.id]) {
            for (const tgt of Q_INPUTS[input.id]) {
                if (tgt !== msg.src && IFRAMES[tgt]) {
                    response.tgt = tgt;
                    IFRAMES[tgt].contentWindow.postMessage(JSON.stringify(response), '*');
                }
            }
        }
        break;

    case 'toggle-visibility':
        element = vle_get_element(msg.target);
        if (element === null) {
            IFRAMES[msg.src].contentWindow.postMessage(JSON.stringify({
                version: 'STACK-JS:1.0.0', type: 'error',
                msg: 'Failed to find element: "' + msg.target + '"', tgt: msg.src
            }), '*');
            return;
        }
        if (msg.set === 'show') { element.style.display = 'block'; vle_update_dom(element); }
        else if (msg.set === 'hide') element.style.display = 'none';
        break;

    case 'change-content':
        // iframe wants to replace the contents of some element on the page
        element = vle_get_element(msg.target);
        if (element === null) {
            response.type = 'error';
            response.msg = 'Failed to find element: "' + msg.target + '"';
            response.tgt = msg.src;
            IFRAMES[msg.src].contentWindow.postMessage(JSON.stringify(response), '*');
            return;
        }
        element.replaceChildren(vle_html_sanitize(msg.content));
        vle_update_dom(element);
        break;

    case 'get-content':
        // iframe is asking what's currently in some element
        element = vle_get_element(msg.target);
        response.type = 'xfer-content';
        response.tgt = msg.src;
        response.target = msg.target;
        response.content = element ? element.innerHTML : null;
        IFRAMES[msg.src].contentWindow.postMessage(JSON.stringify(response), '*');
        break;

    case 'resize-frame':
        // iframe is telling us it needs more/less room
        element = IFRAMES[msg.src].parentElement;
        element.style.width = msg.width;
        element.style.height = msg.height;
        IFRAMES[msg.src].style.width = '100%';
        IFRAMES[msg.src].style.height = '100%';
        vle_update_dom(element);
        break;

    case 'ping':
        response.type = 'ping';
        response.tgt = msg.src;
        IFRAMES[msg.src].contentWindow.postMessage(JSON.stringify(response), '*');
        return;

    case 'initial-input':
    case 'error':
        // these are responses to messages we sent, nothing to do here
        break;

    default:
        response.type = 'error';
        response.msg = 'Unknown message-type: "' + msg.type + '"';
        response.tgt = msg.src;
        IFRAMES[msg.src].contentWindow.postMessage(JSON.stringify(response), '*');
    }
});

// builds and inserts a sandboxed iframe for a STACK question component
function create_iframe(iframeid, content, targetdivid, title, scrolling, evil) {
    const frm = document.createElement('iframe');
    frm.id = iframeid;
    frm.style.width = '100%';
    frm.style.height = '100%';
    frm.style.border = 0;
    if (scrolling === false) {
        frm.scrolling = 'no';
        frm.style.overflow = 'hidden';
    } else {
        frm.scrolling = 'yes';
    }
    frm.title = title;
    frm.referrerpolicy = 'no-referrer';
    if (!evil) {
        // allow-same-origin lets <base href> control relative URL resolution
        // inside the iframe — content here comes from our own STACK API, not
        // arbitrary user input, so this is safe
        frm.sandbox = 'allow-scripts allow-downloads allow-same-origin';
    }
    frm.srcdoc = content;

    const targetDiv = document.getElementById(targetdivid);
    targetDiv.replaceChildren(frm);
    IFRAMES[iframeid] = frm;

    // remember which question this iframe belongs to
    const boundary = vle_get_question_boundary(targetDiv);
    if (boundary && boundary.id) {
        IFRAME_TO_BOUNDARY[iframeid] = boundary.id;
        const reg = getQuestionRegistry(boundary.id);
        reg.iframes[iframeid] = frm;
    }
}