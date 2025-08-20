// SPLICE resize handling - https://cssplice.org/
// Expected message format:
// {
//   subject: lti.frameResize',
//   message_id: (a unique string ID),  // optional - not used
//   height: ...,
//   width: ...
// }

window.addEventListener('message', function (event) {
    let edata = event.data;

    //MoM sends event.data as a string instead of JSON
    if (typeof event.data == 'string' && event.data.match(/lti\.frameResize/)) {
        edata = JSON.parse(event.data);
    }

    if (edata.subject === "lti.frameResize") {
        if ("frame_id" in edata) {
            // MoM may send frame_id
            let el = document.getElementById(edata['frame_id']);
            document.getElementById(edata['frame_id']).style.height = edata.height + 'px';
            if (edata.wrapheight && document.getElementById(edata['frame_id'] + 'wrap')) {
                document.getElementById(edata['frame_id'] + 'wrap').style.height = edata.wrapheight + 'px';
            }
        } else if ("iframe_resize_id" in edata) {
            // MoM may send iframe_resize_id
            document.getElementById(edata['iframe_resize_id']).style.height = edata.height + 'px';
        } else {
            // No target element specified, so resize the iframe that sent the message
            // event.source.frameElement is only accessible if the iframe is on the same domain
            // so loop through iframes to find the one that sent the message
            const iFrames = document.getElementsByTagName('iframe');
            for(const iFrame of iFrames) {
                if(iFrame.contentWindow === event.source) {
                    if (edata.height) iFrame.height = edata.height;
                    if (edata.width) iFrame.width = edata.width;
                    break;
                }
            }
        }
    }
  });

  // Currently only used by My Open Math to request a resize after knowls open
  function sendResizeRequest(el) {
    el.contentWindow.postMessage("requestResize", "*");
  }
