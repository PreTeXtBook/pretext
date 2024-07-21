window.addEventListener('message', function(event) {
    if (typeof event.data=='string' && event.data.match(/lti\.frameResize/)) {
        var edata = JSON.parse(event.data);
        if ("frame_id" in edata) {
            document.getElementById(edata['frame_id']).style.height = edata.height + 'px';
            if (edata.wrapheight && document.getElementById(edata['frame_id'] + 'wrap')) {
                document.getElementById(edata['frame_id'] + 'wrap').style.height = edata.wrapheight + 'px';
            }
        } else if ("iframe_resize_id" in edata) {
            document.getElementById(edata['iframe_resize_id']).style.height = edata.height + 'px';
        }
    }
});

function sendResizeRequest(el) {
    el.contentWindow.postMessage("requestResize", "*");
}