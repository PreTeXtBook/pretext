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

    'use strict';
    // Note the VLE specific include of logic.

    /* All the IFRAMES have unique identifiers that they give in their
     * messages. But we only work with those that have been created by
     * our logic and are found from this map.
     */
    let IFRAMES = {};

    /* For event handling, lists of IFRAMES listening particular inputs.
     */
    let INPUTS = {};

    /* For event handling, lists of IFRAMES listening particular inputs
     * and their input events. By default we only listen to changes.
     * We report input events as changes to the other side.
     */
    let INPUTS_INPUT_EVENT = {};

    /* A flag to disable certain things. */
    let DISABLE_CHANGES = false;


    /**
     * Returns an element with a given id, if an only if that element exists
     * inside a portion of DOM that represents a question.
     *
     * If not found or exists outside the restricted area then returns `null`.
     *
     * @param {String} id the identifier of the element we want.
     */
    function vle_get_element(id) {
        /* In the case of Moodle we are happy as long as the element is inside
           something with the `formulation`-class. */
        let candidate = document.getElementById(id);
        let iter = candidate;
        while (iter && !iter.classList.contains('formulation')) {
            iter = iter.parentElement;
        }
        if (iter && iter.classList.contains('formulation')) {
            return candidate;
        }

        return null;
    }

    /**
     * Returns an input element with a given name, if and only if that element
     * exists inside a portion of DOM that represents a question.
     *
     * Note that, the input element may have a name that multiple questions
     * use and to pick the preferred element one needs to pick the one
     * within the same question as the IFRAME.
     *
     * Note that the input can also be a select. In the case of radio buttons
     * returning one of the possible buttons is enough.
     *
     * If not found or exists outside the restricted area then returns `null`.
     *
     * @param {String} name the name of the input we want
     * @param {String} srciframe the identifier of the iframe wanting it
     */
    function vle_get_input_element(name, srciframe) {
        /* In the case of Moodle we are happy as long as the element is inside
           something with the `formulation`-class. */
        let initialcandidate = document.getElementById(srciframe);
        let iter = initialcandidate;
        while (iter && !iter.classList.contains('formulation')) {
            iter = iter.parentElement;
        }
        if (iter && iter.classList.contains('formulation')) {
            // iter now represents the borders of the question containing
            // this IFRAME.
            let possible = iter.querySelector('input[id$="_' + name + '"]');
            if (possible !== null) {
                return possible;
            }
            // Radios have interesting ids, but the name makes sense
            possible = iter.querySelector('input[id$="_' + name + '_1"][type=radio]');
            if (possible !== null) {
                return possible;
            }
            possible = iter.querySelector('select[id$="_' + name + '"]');
            if (possible !== null) {
                return possible;
            }
        }
        // If none found within the question itself, search everywhere.
        let possible = document.querySelector('.formulation input[id$="_' + name + '"]');
        if (possible !== null) {
            return possible;
        }
        // Radios have interesting ids, but the name makes sense
        possible = document.querySelector('.formulation input[id$="_' + name + '_1"][type=radio]');
        if (possible !== null) {
            return possible;
        }
        possible = document.querySelector('.formulation select[id$="_' + name + '"]');
        return possible;
    }

    /**
     * Triggers any VLE specific scripting related to updates of the given
     * input element.
     *
     * @param {HTMLElement} inputelement the input element that has changed
     */
    function vle_update_input(inputelement) {
        // Triggering a change event may be necessary.
        const c = new Event('change');
        inputelement.dispatchEvent(c);
        // Also there are those that listen to input events.
        const i = new Event('input');
        inputelement.dispatchEvent(i);
    }

    /**
     * Triggers any VLE specific scripting related to DOM updates.
     *
     * @param {HTMLElement} modifiedsubtreerootelement element under which changes may have happened.
     */
    function vle_update_dom(modifiedsubtreerootelement) {
        CustomEvents.notifyFilterContentUpdated(modifiedsubtreerootelement);
    }

    /**
     * Does HTML-string cleaning, i.e., removes any script payload. Returns
     * a DOM version of the given input string.
     *
     * This is used when receiving replacement content for a div.
     *
     * @param {String} src a raw string to sanitise
     */
    function vle_html_sanitize(src) {
        // This can be implemented with many libraries or by custom code
        // however as this is typically a thing that a VLE might already have
        // tools for we have it at this level so that the VLE can use its own
        // tools that do things that the VLE developpers consider safe.

        // As Moodle does not currently seem to have such a sanitizer in
        // the core libraries, here is one implementation that shows what we
        // are looking for.

        // TO-DO: look into replacing this with DOMPurify or some such.

        let parser = new DOMParser();
        let doc = parser.parseFromString(src, "text/html");

        // First remove all <script> tags. Also <style> as we do not want
        // to include too much style.
        for (let el of doc.querySelectorAll('script, style')) {
            el.remove();
        }

        // Check all elements for attributes.
        for (let el of doc.querySelectorAll('*')) {
            for (let {name, value} of el.attributes) {
                if (is_evil_attribute(name, value)) {
                    el.removeAttribute(name);
                }
            }
        }

        return doc.body;
    }

    /**
     * Utility function trying to determine if a given attribute is evil
     * when sanitizing HTML-fragments.
     *
     * @param {String} name the name of an attribute.
     * @param {String} value the value of an attribute.
     */
    function is_evil_attribute(name, value) {
        const lcname = name.toLowerCase();
        if (lcname.startsWith('on')) {
            // We do not allow event listeners to be defined.
            return true;
        }
        if (lcname === 'src' || lcname.endsWith('href')) {
            // Do not allow certain things in the urls.
            const lcvalue = value.replace(/\s+/g, '').toLowerCase();
            // Ignore es-lint false positive.
            /* eslint-disable no-script-url */
            if (lcvalue.includes('javascript:') || lcvalue.includes('data:text')) {
                return true;
            }
        }

        return false;
    }


    /*************************************************************************
     * Above this are the bits that one would probably tune when porting.
     *
     * Below is the actuall message handling and it should be left alone.
     */
    window.addEventListener("message", (e) => {
        // NOTE! We do not check the source or origin of the message in
        // the normal way. All actions that can bypass our filters to trigger
        // something are largely irrelevant and all traffic will be kept
        // "safe" as anyone could be listening.

        // All messages we receive are strings, anything else is for someone
        // else and will be ignored.
        if (!(typeof e.data === 'string' || e.data instanceof String)) {
            return;
        }

        // That string is a JSON encoded dictionary.
        let msg = null;
        try {
            msg = JSON.parse(e.data);
        } catch (e) {
            // Only JSON objects that are parseable will work.
            return;
        }

        // All messages we handle contain a version field with a particular
        // value, for now we leave the possibility open for that value to have
        // an actual version number suffix...
        if (!(('version' in msg) && msg.version.startsWith('STACK-JS'))) {
            return;
        }

        // All messages we handle must have a source and a type,
        // and that source must be one of the registered ones.
        if (!(('src' in msg) && ('type' in msg) && (msg.src in IFRAMES))) {
            return;
        }
        let element = null;
        let input = null;

        let response = {
            version: 'STACK-JS:1.1.0'
        };

        switch (msg.type) {
        case 'register-input-listener':
            // 1. Find the input.
            input = vle_get_input_element(msg.name, msg.src);

            if (input === null) {
                // Requested something that is not available.
                response.type = 'error';
                response.msg = 'Failed to connect to input: "' + msg.name + '"';
                response.tgt = msg.src;
                IFRAMES[msg.src].contentWindow.postMessage(JSON.stringify(response), '*');
                return;
            }

            response.type = 'initial-input';
            response.name = msg.name;
            response.tgt = msg.src;

            // 2. What type of an input is this? Note that we do not
            // currently support all types in sensible ways. In particular,
            // anything with multiple values will be a problem.
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
                response['input-readonly'] = input.hasAttribute('disabled');
                response.value = '';
                for (let inp of document.querySelectorAll('input[type=radio][name=' + CSS.escape(input.name) + ']')) {
                    if (inp.checked) {
                        response.value = inp.value;
                    }
                }
            }

            // 3. Add listener for changes of this input.
            if (input.id in INPUTS) {
                if (msg.src in INPUTS[input.id]) {
                    // DO NOT BIND TWICE!
                    return;
                }
                if (input.type !== 'radio') {
                    INPUTS[input.id].push(msg.src);
                } else {
                    let radgroup = document.querySelectorAll('input[type=radio][name=' + CSS.escape(input.name) + ']');
                    for (let inp of radgroup) {
                        INPUTS[inp.id].push(msg.src);
                    }
                }
            } else {
                if (input.type !== 'radio') {
                    INPUTS[input.id] = [msg.src];
                } else {
                    let radgroup = document.querySelectorAll('input[type=radio][name=' + CSS.escape(input.name) + ']');
                    for (let inp of radgroup) {
                        INPUTS[inp.id] = [msg.src];
                    }
                }
                if (input.type !== 'radio') {
                    input.addEventListener('change', () => {
                        if (DISABLE_CHANGES) {
                            return;
                        }
                        let resp = {
                            version: 'STACK-JS:1.0.0',
                            type: 'changed-input',
                            name: msg.name
                        };
                        if (input.type === 'checkbox') {
                            resp['value'] = input.checked;
                        } else {
                            resp['value'] = input.value;
                        }
                        for (let tgt of INPUTS[input.id]) {
                            resp['tgt'] = tgt;
                            IFRAMES[tgt].contentWindow.postMessage(JSON.stringify(resp), '*');
                        }
                    });
                } else {
                    // Assume that if we received a radio button that is safe
                    // then all its friends are also safe.
                    let radgroup = document.querySelectorAll('input[type=radio][name=' + CSS.escape(input.name) + ']');
                    radgroup.forEach((inp) => {
                        inp.addEventListener('change', () => {
                            if (DISABLE_CHANGES) {
                                return;
                            }
                            let resp = {
                                version: 'STACK-JS:1.0.0',
                                type: 'changed-input',
                                name: msg.name
                            };
                            if (inp.checked) {
                                resp.value = inp.value;
                            } else {
                                // What about unsetting?
                                return;
                            }
                            for (let tgt of INPUTS[inp.id]) {
                                resp['tgt'] = tgt;
                                IFRAMES[tgt].contentWindow.postMessage(JSON.stringify(resp), '*');
                            }
                        });
                    });
                }
            }

            if (('track-input' in msg) && msg['track-input'] && input.type !== 'radio') {
                if (input.id in INPUTS_INPUT_EVENT) {
                    if (msg.src in INPUTS_INPUT_EVENT[input.id]) {
                        // DO NOT BIND TWICE!
                        return;
                    }
                    INPUTS_INPUT_EVENT[input.id].push(msg.src);
                } else {
                    INPUTS_INPUT_EVENT[input.id] = [msg.src];

                    input.addEventListener('input', () => {
                        if (DISABLE_CHANGES) {
                            return;
                        }
                        let resp = {
                            version: 'STACK-JS:1.0.0',
                            type: 'changed-input',
                            name: msg.name
                        };
                        if (input.type === 'checkbox') {
                            resp['value'] = input.checked;
                        } else {
                            resp['value'] = input.value;
                        }
                        for (let tgt of INPUTS_INPUT_EVENT[input.id]) {
                            resp['tgt'] = tgt;
                            IFRAMES[tgt].contentWindow.postMessage(JSON.stringify(resp), '*');
                        }
                    });
                }
            }

            // 4. Let the requester know that we have bound things
            //    and let it know the initial value.
            if (!(msg.src in INPUTS[input.id])) {
                IFRAMES[msg.src].contentWindow.postMessage(JSON.stringify(response), '*');
            }

            break;
        case 'changed-input':
            // 1. Find the input.
            input = vle_get_input_element(msg.name, msg.src);

            if (input === null) {
                // Requested something that is not available.
                const ret = {
                    version: 'STACK-JS:1.0.0',
                    type: 'error',
                    msg: 'Failed to modify input: "' + msg.name + '"',
                    tgt: msg.src
                };
                IFRAMES[msg.src].contentWindow.postMessage(JSON.stringify(ret), '*');
                return;
            }

            // Disable change events.
            DISABLE_CHANGES = true;

            // TO-DO: Radio buttons should we check that value is possible?
            if (input.type === 'checkbox') {
                input.checked = msg.value;
            } else {
                input.value = msg.value;
            }

            // Trigger VLE side actions.
            vle_update_input(input);

            // Enable change tracking.
            DISABLE_CHANGES = false;

            // Tell all other frames, that care, about this.
            response.type = 'changed-input';
            response.name = msg.name;
            response.value = msg.value;

            for (let tgt of INPUTS[input.id]) {
                if (tgt !== msg.src) {
                    response.tgt = tgt;
                    IFRAMES[tgt].contentWindow.postMessage(JSON.stringify(response), '*');
                }
            }

            break;
        case 'toggle-visibility':
            // 1. Find the element.
            element = vle_get_element(msg.target);

            if (element === null) {
                // Requested something that is not available.
                const ret = {
                    version: 'STACK-JS:1.0.0',
                    type: 'error',
                    msg: 'Failed to find element: "' + msg.target + '"',
                    tgt: msg.src
                };
                IFRAMES[msg.src].contentWindow.postMessage(JSON.stringify(ret), '*');
                return;
            }

            // 2. Toggle display setting.
            if (msg.set === 'show') {
                element.style.display = 'block';
                // If we make something visible we should let the VLE know about it.
                vle_update_dom(element);
            } else if (msg.set === 'hide') {
                element.style.display = 'none';
            }

            break;
        case 'change-content':
            // 1. Find the element.
            element = vle_get_element(msg.target);

            if (element === null) {
                // Requested something that is not available.
                response.type = 'error';
                response.msg = 'Failed to find element: "' + msg.target + '"';
                response.tgt = msg.src;
                IFRAMES[msg.src].contentWindow.postMessage(JSON.stringify(response), '*');
                return;
            }

            // 2. Secure content.
            // 3. Switch the content.
            element.replaceChildren(vle_html_sanitize(msg.content));
            // If we tune something we should let the VLE know about it.
            vle_update_dom(element);

            break;
        case 'get-content':
            // 1. Find the element.
            element = vle_get_element(msg.target);
            // 2. Build the message.
            response.type = 'xfer-content';
            response.tgt = msg.src;
            response.target = msg.target;
            response.content = null;
            if (element !== null) {
                // TO-DO: Should we sanitise the content? Probably not as using
                // this to interrogate neighbouring questions only allows
                // messing with the other questions and not anything outside
                // them. If we do not sanitise it we allow some interesting
                // question-analytics tooling, and if we do we really don't
                // gain anything sensible.
                // Matti's opinnion is to not sanitise at this point as
                // interraction between questions is not inherently evil
                // and could be of use even at the level of reading code from
                // from other questions.
                response.content = element.innerHTML;
            }
            IFRAMES[msg.src].contentWindow.postMessage(JSON.stringify(response), '*');
            break;
        case 'resize-frame':
            // 1. Find the frames wrapper div.
            element = IFRAMES[msg.src].parentElement;

            // 2. Set the wrapper size.
            element.style.width = msg.width;
            element.style.height = msg.height;

            // 3. Reset the frame size.
            IFRAMES[msg.src].style.width = '100%';
            IFRAMES[msg.src].style.height = '100%';

            // Only touching the size but still let the VLE know.
            vle_update_dom(element);
            break;
        case 'ping':
            // This is for testing the connection. The other end will
            // send these untill it receives a reply.
            // Part of the logic for startup.
            response.type = 'ping';
            response.tgt = msg.src;

            IFRAMES[msg.src].contentWindow.postMessage(JSON.stringify(response), '*');
            return;
        case 'initial-input':
        case 'error':
            // These message types are for the other end.
            break;

        default:
            // If we see something unexpected, lets let the other end know
            // and make sure that they know our version. Could be that this
            // end has not been upgraded.
            response.type = 'error';
            response.msg = 'Unknown message-type: "' + msg.type + '"';
            response.tgt = msg.src;

            IFRAMES[msg.src].contentWindow.postMessage(JSON.stringify(response), '*');
        }

    });



        /* To avoid any logic that forbids IFRAMEs in the VLE output one can
           also create and register that IFRAME through this logic. This
           also ensures that all relevant security settigns for that IFRAME
           have been correctly tuned.

           Here the IDs are for the secrect identifier that may be present
           inside the content of that IFRAME and for the question that contains
           it. One also identifies a DIV element that marks the position of
           the IFRAME and limits the size of the IFRAME (all IFRAMEs this
           creates will be 100% x 100%).

           @param {String} iframeid the id that the IFRAME has stored inside
                  it and uses for communication.
           @param {String} the full HTML content of that IFRAME.
           @param {String} targetdivid the id of the element (div) that will
                  hold the IFRAME.
           @param {String} title a descriptive name for the iframe.
           @param {bool} scrolling whether we have overflow:scroll or
                  overflow:hidden.
           @param {bool} evil allows certain special cases to act without
                  sandboxing, this is a feature that will be removed so do
                  not rely on it only use it to test STACK-JS before you get your
                  thing to run in a sandbox.
         */
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
            // Somewhat random limitation.
            frm.referrerpolicy = 'no-referrer';
            // We include that allow-downloads as an example of XLS-
            // document building in JS has been seen.
            // UNDER NO CIRCUMSTANCES DO WE ALLOW-SAME-ORIGIN!
            // That would defeat the whole point of this.
            if (!evil) {
                frm.sandbox = 'allow-scripts allow-downloads';
            }

            // As the SOP is intentionally broken we need to allow
            // scripts from everywhere.

            // NOTE: this bit commented out as long as the csp-attribute
            // is not supported by more browsers.
            // frm.csp = "script-src: 'unsafe-inline' 'self' '*';";
            // frm.csp = "script-src: 'unsafe-inline' 'self' '*';img-src: '*';";

            // Plug the content into the frame.
            frm.srcdoc = content;

            // The target DIV will have its children removed.
            // This allows that div to contain some sort of loading
            // indicator until we plug in the frame.
            // Naturally the frame will then start to load itself.
            document.getElementById(targetdivid).replaceChildren(frm);
            IFRAMES[iframeid] = frm;


    };