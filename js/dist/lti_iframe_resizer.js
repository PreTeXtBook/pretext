window.addEventListener("message", function(event) {
  let edata = event.data;
  if (typeof event.data == "string" && event.data.match(/lti\.frameResize/)) {
    edata = JSON.parse(event.data);
  }
  if (edata.subject === "lti.frameResize") {
    if ("frame_id" in edata) {
      let el = document.getElementById(edata["frame_id"]);
      document.getElementById(edata["frame_id"]).style.height = edata.height + "px";
      if (edata.wrapheight && document.getElementById(edata["frame_id"] + "wrap")) {
        document.getElementById(edata["frame_id"] + "wrap").style.height = edata.wrapheight + "px";
      }
    } else if ("iframe_resize_id" in edata) {
      document.getElementById(edata["iframe_resize_id"]).style.height = edata.height + "px";
    } else {
      const iFrames = document.getElementsByTagName("iframe");
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
function sendResizeRequest(el) {
  el.contentWindow.postMessage("requestResize", "*");
}
//# sourceMappingURL=lti_iframe_resizer.js.map
