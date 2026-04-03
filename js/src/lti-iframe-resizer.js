/**
 * LTI iframe resizer (from lti_iframe_resizer.js).
 *
 * Handles SPLICE resize messages from embedded iframes (e.g. MyOpenMath),
 * adjusting iframe dimensions based on postMessage events.
 *
 * @see https://cssplice.org/
 */

export function sendResizeRequest(el) {
    el.contentWindow.postMessage("requestResize", "*");
}

export function initLtiIframeResizer() {
    window.addEventListener("message", function (event) {
        let edata = event.data;

        // MoM sends event.data as a string instead of JSON
        if (
            typeof event.data == "string" &&
            event.data.match(/lti\.frameResize/)
        ) {
            edata = JSON.parse(event.data);
        }

        if (edata.subject === "lti.frameResize") {
            if ("frame_id" in edata) {
                const el = document.getElementById(edata["frame_id"]);
                if (el) {
                    el.style.height = edata.height + "px";
                }
                if (
                    edata.wrapheight &&
                    document.getElementById(edata["frame_id"] + "wrap")
                ) {
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
                const iFrames =
                    document.getElementsByTagName("iframe");
                for (const iFrame of iFrames) {
                    if (iFrame.contentWindow === event.source) {
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
