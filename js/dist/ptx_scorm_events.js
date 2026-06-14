(function() {
  "use strict";
  var _api = null;
  var _ver = null;
  (function discoverApi() {
    var win = window;
    for (var i = 0; i < 10; i++) {
      if (win.API_1484_11) {
        _api = win.API_1484_11;
        _ver = "2004";
        return;
      }
      if (win.API) {
        _api = win.API;
        _ver = "1.2";
        return;
      }
      if (win.parent === win) break;
      win = win.parent;
    }
    console.warn("[PTX-SCORM] No SCORM API found. Exercises will work normally but scores will not be reported.");
  })();
  function Get(key) {
    if (!_api) return "";
    var val = _ver === "2004" ? _api.GetValue(key) : _api.LMSGetValue(key);
    return String(val);
  }
  function Set(key, val) {
    if (!_api) return;
    if (_ver === "2004") {
      _api.SetValue(key, String(val));
    } else {
      _api.LMSSetValue(key, String(val));
    }
  }
  function Commit() {
    if (!_api) return;
    if (_ver === "2004") {
      _api.Commit("");
    } else {
      _api.LMSCommit("");
    }
  }
  function lastError() {
    if (!_api) return "0";
    var code = _ver === "2004" ? _api.GetLastError() : _api.LMSGetLastError();
    return String(code);
  }
  var _initialized = false;
  var _state = {
    correct: 0,
    // sum of percentage scores for graded questions
    graded: 0,
    // total number of graded question answers received
    iCount: 0,
    // next available cmi.interactions index (session-local)
    answers: {}
    // {divId: {answer, correct, percent}} — persisted across sessions
  };
  var _doenetStates = {};
  var _doenetRestoreReady = false;
  var _pendingGetStateRequests = [];
  var _doenetSentStateAt = {};
  var DOENET_INIT_WINDOW_MS = 8e3;
  var _totalQuestions = 0;
  var _learnerId = "";
  function lsKey() {
    return "ptx-scorm:" + (_learnerId || "anon") + ":" + window.location.pathname;
  }
  function saveToLocalStorage() {
    try {
      localStorage.setItem(lsKey(), JSON.stringify(_state));
    } catch (e) {
    }
  }
  function loadFromLocalStorage() {
    try {
      var raw = localStorage.getItem(lsKey());
      return raw ? JSON.parse(raw) : null;
    } catch (e) {
      return null;
    }
  }
  function saveDoenetState(divId, state) {
    if (!divId || state === null || state === void 0) return;
    _doenetStates[divId] = state;
    try {
      var str = typeof state === "string" ? state : JSON.stringify(state);
      localStorage.setItem(lsKey() + "|doenet|" + divId, str);
    } catch (e) {
    }
  }
  function loadDoenetState(divId) {
    if (_doenetStates[divId]) return _doenetStates[divId];
    try {
      var raw = localStorage.getItem(lsKey() + "|doenet|" + divId);
      if (raw) {
        _doenetStates[divId] = JSON.parse(raw);
        return _doenetStates[divId];
      }
    } catch (e) {
    }
    return null;
  }
  function resolveIframeId(sourceWindow) {
    var iframes = document.getElementsByTagName("iframe");
    for (var i = 0; i < iframes.length; i++) {
      if (iframes[i].contentWindow === sourceWindow) {
        var c = iframes[i].closest('[data-component="splice"],[data-component="doenet"]');
        return c && c.id || iframes[i].id || null;
      }
    }
    return null;
  }
  function respondToGetState(sourceWindow, messageId) {
    var divId = resolveIframeId(sourceWindow);
    var stateObj = divId ? loadDoenetState(divId) : null;
    console.log('[PTX-SCORM] SPLICE.getState from "' + (divId || "?") + '" \u2014 ' + (stateObj ? "sending saved state (cid: " + (stateObj.cid || "?") + ")" : "no saved state (first visit)"));
    if (divId) _doenetSentStateAt[divId] = Date.now();
    sourceWindow.postMessage({
      subject: "SPLICE.getState.response",
      message_id: messageId,
      state: stateObj || null
    }, "*");
  }
  function initSession() {
    if (_initialized || !_api) return;
    var result = _ver === "2004" ? _api.Initialize("") : _api.LMSInitialize("");
    var err = lastError();
    if (result !== "true" && err !== "103") {
      console.warn("[PTX-SCORM] Initialize() failed (error=" + err + "). Score reporting will be disabled for this page.");
      return;
    }
    _initialized = true;
    var raw = Get("cmi.suspend_data");
    if (raw) {
      try {
        Object.assign(_state, JSON.parse(raw));
      } catch (e) {
        console.warn("[PTX-SCORM] Could not parse suspend_data:", e);
      }
    }
    var lmsCount = parseInt(Get("cmi.interactions._count") || "0", 10);
    _state.iCount = isNaN(lmsCount) ? 0 : lmsCount;
    var completionKey = _ver === "2004" ? "cmi.completion_status" : "cmi.core.lesson_status";
    var currentStatus = Get(completionKey);
    if (currentStatus === "not attempted" || currentStatus === "unknown" || currentStatus === "") {
      Set(completionKey, "incomplete");
      Commit();
    }
    console.log("[PTX-SCORM] Session ready (SCORM " + _ver + ").  Prior interactions: " + _state.iCount + ",  Prior score: " + _state.correct + "/" + _state.graded);
  }
  var RUNESTONE_TO_SCORM_TYPE = {
    mChoice: "choice",
    // Multiple-choice question
    clickableArea: "choice",
    // Clickable-area question (pick the right region)
    fillb: "fill-in",
    // Fill-in-the-blank
    webwork: "fill-in",
    // WeBWorK problem (scored as fill-in)
    parsons: "sequencing",
    // Parsons problem (arrange code blocks in order)
    hparsonsAnswer: "sequencing",
    // Horizontal Parsons variant
    dragNdrop: "matching",
    // Drag-and-drop matching
    matching: "matching",
    // Traditional matching exercise
    unittest: "performance",
    // ActiveCode with unit tests (auto-graded)
    shortanswer: "long-fill-in",
    // Short-answer / journal (no automatic grade)
    splice: "performance",
    // SPLICE protocol iframe activity (see Section 10)
    // DoenetActivity events: Runestone's SpliceWrapper fires logBookEvent with
    // event="SPLICE.reportScoreAndState" (carries score/percent/answer) and
    // event="SPLICE.sendEvent" (notification only, no score).  Only the former
    // should be recorded; the latter has no score and is silently ignored.
    "SPLICE.reportScoreAndState": "performance"
  };
  var GRADEABLE_SELECTORS = [
    '[data-component="multiplechoice"]',
    '[data-component="parsons"]',
    '[data-component="hparsons"]',
    '[data-component="fillintheblank"]',
    '[data-component="dragndrop"]',
    '[data-component="matching"]',
    '[data-component="clickablearea"]',
    '[data-component="webwork"]',
    '[data-component="splice"]',
    // SPLICE protocol iframe activities
    '[data-component="doenet"]'
    // DoenetActivity (SCORM/Runestone builds)
  ];
  function countPageQuestions() {
    var count = 0;
    GRADEABLE_SELECTORS.forEach(function(sel) {
      count += document.querySelectorAll(sel).length;
    });
    document.querySelectorAll('[data-component="activecode"] textarea').forEach(function(ta) {
      if (ta.value && ta.value.indexOf("--unittest--") !== -1 || ta.textContent && ta.textContent.indexOf("--unittest--") !== -1) {
        count++;
      }
    });
    _totalQuestions = count;
    console.log("[PTX-SCORM] Gradeable questions on this page: " + _totalQuestions);
  }
  function extractScore(ev) {
    if (typeof ev.percent === "number") {
      return ev.percent;
    }
    if (ev.act) {
      var unitMatch = ev.act.match(/(?:^|:)percent:([\d.]+)/);
      if (unitMatch) return parseFloat(unitMatch[1]) / 100;
      var pctMatch = ev.act.match(/pct:([\d.]+)/);
      if (pctMatch) return parseFloat(pctMatch[1]);
    }
    var c = ev.correct;
    if (c === "T" || c === true) return 1;
    if (c === "F" || c === false) return 0;
    return null;
  }
  function isoTimestamp() {
    return (/* @__PURE__ */ new Date()).toISOString().replace(/\.\d{3}Z$/, "Z");
  }
  function hhmmssTime() {
    var d = /* @__PURE__ */ new Date();
    return ("0" + d.getHours()).slice(-2) + ":" + ("0" + d.getMinutes()).slice(-2) + ":" + ("0" + d.getSeconds()).slice(-2);
  }
  function recordInteraction(ev) {
    var scormType = RUNESTONE_TO_SCORM_TYPE[ev.event];
    if (!scormType) {
      return;
    }
    initSession();
    if (!_initialized) {
      console.warn(
        "[PTX-SCORM] recordInteraction: aborting \u2014 session not initialized.",
        "_api:",
        !!_api,
        "_ver:",
        _ver
      );
      return;
    }
    if (_ver === "1.2" && scormType === "long-fill-in") {
      scormType = "fill-in";
    }
    var score = extractScore(ev);
    if (ev.event === "SPLICE.reportScoreAndState" && score !== null) {
      var sentAt = _doenetSentStateAt[ev.div_id];
      if (sentAt && Date.now() - sentAt < DOENET_INIT_WINDOW_MS) {
        var prevSaved = _state.answers[ev.div_id];
        var prevPct = prevSaved && typeof prevSaved.percent === "number" ? prevSaved.percent : null;
        if (prevPct !== null && score <= prevPct) {
          console.log('[PTX-SCORM] Ignoring Doenet init auto-report for "' + ev.div_id + '" \u2014 score ' + score + " \u2264 saved " + prevPct + " (initialization window)");
          if (ev.state) saveDoenetState(ev.div_id, ev.state);
          return;
        }
      }
      delete _doenetSentStateAt[ev.div_id];
    }
    var idx = _state.iCount;
    var prefix = "cmi.interactions." + idx + ".";
    Set(prefix + "id", (ev.div_id || "unknown").substring(0, 255));
    Set(prefix + "type", scormType);
    if (_ver === "2004") {
      Set(prefix + "timestamp", isoTimestamp());
    } else {
      Set(prefix + "time", hhmmssTime());
    }
    var response = ev.answer != null ? ev.answer : ev.act || "";
    if (typeof response !== "string") {
      response = JSON.stringify(response);
    }
    var responseKey = _ver === "2004" ? "learner_response" : "student_response";
    Set(prefix + responseKey, response.substring(0, 255));
    var result;
    if (score === null) result = "neutral";
    else if (score >= 1) result = "correct";
    else if (score <= 0) result = "incorrect";
    else result = score.toFixed(4);
    Set(prefix + "result", result);
    _state.iCount++;
    if (score !== null) {
      var prevEntry = _state.answers[ev.div_id || "unknown"];
      if (prevEntry !== void 0 && prevEntry.percent !== null && prevEntry.percent !== void 0) {
        _state.correct -= prevEntry.percent;
        _state.graded -= 1;
      }
      _state.correct += score;
      _state.graded += 1;
      var denom = _totalQuestions > 0 ? _totalQuestions : _state.graded;
      var scaled = _state.correct / denom;
      if (_ver === "2004") {
        Set("cmi.score.scaled", scaled.toFixed(4));
        Set("cmi.score.raw", (scaled * 100).toFixed(1));
        Set("cmi.score.min", "0");
        Set("cmi.score.max", "100");
      } else {
        Set("cmi.core.score.raw", (scaled * 100).toFixed(1));
      }
    }
    _state.answers[ev.div_id || "unknown"] = {
      answer: response,
      correct: score === null ? null : score >= 1,
      percent: score
    };
    if (ev.state) {
      saveDoenetState(ev.div_id || "unknown", ev.state);
    }
    var suspendJson = JSON.stringify(_state);
    Set("cmi.suspend_data", suspendJson);
    var setErr = lastError();
    if (setErr !== "0") {
      console.warn("[PTX-SCORM] Set(cmi.suspend_data) error code:", setErr);
    }
    Commit();
    var commitErr = lastError();
    if (commitErr !== "0") {
      console.warn("[PTX-SCORM] Commit() error code:", commitErr);
    }
    saveToLocalStorage();
    var logDenom = _totalQuestions > 0 ? _totalQuestions : _state.graded;
    var pctLabel = logDenom > 0 ? (_state.correct / logDenom * 100).toFixed(0) + "% (" + _state.correct.toFixed(2) + " / " + logDenom + ")" : "n/a";
    console.log("[PTX-SCORM] " + ev.event + ' "' + (ev.div_id || "?") + '" \u2192 ' + result + "  Score: " + pctLabel + "  (" + _state.iCount + " total interactions)");
  }
  function installHook() {
    if (!window.RunestoneBase || window.RunestoneBase.__ptxScormHooked) return;
    var originalLogBookEvent = window.RunestoneBase.prototype.logBookEvent;
    window.RunestoneBase.prototype.logBookEvent = function(eventData) {
      try {
        recordInteraction(eventData);
      } catch (err) {
        console.error("[PTX-SCORM] Error in recordInteraction:", err);
      }
      return originalLogBookEvent.call(this, eventData);
    };
    window.RunestoneBase.__ptxScormHooked = true;
    var rsVersion = window.eBookConfig && window.eBookConfig.runestone_version ? " (Runestone v" + window.eBookConfig.runestone_version + ")" : "";
    console.log("[PTX-SCORM] Runestone hook installed" + rsVersion + ".");
  }
  installHook();
  document.addEventListener("runestone:pre-login-complete", installHook);
  document.addEventListener("DOMContentLoaded", function() {
    installHook();
    countPageQuestions();
    var restoreMap = loadRestoreData();
    installRestoreHook(restoreMap);
    requestParentResize();
    installWeBWorKSrcdocIntercept();
    installWeBWorKAjaxIntercept();
    Object.keys(_state.answers).forEach(function(divId) {
      var container = document.getElementById(divId);
      if (!container || !container.dataset) return;
      if (container.dataset.domain) {
        addWeBWorKBadge(container, _state.answers[divId]);
      }
      if (container.dataset.component === "doenet") {
        addDoenetBadge(container, _state.answers[divId]);
      }
    });
  });
  function requestParentResize() {
    if (window.parent === window) return;
    var height = Math.max(
      document.documentElement.scrollHeight,
      document.body ? document.body.scrollHeight : 0,
      600
    );
    var msg = { subject: "lti.frameResize", height };
    window.parent.postMessage(msg, "*");
    if (window.top !== window.parent) {
      try {
        window.top.postMessage(msg, "*");
      } catch (e) {
      }
    }
  }
  if (window.ResizeObserver) {
    var _resizeObserver = new ResizeObserver(function() {
      requestParentResize();
    });
    if (document.body) {
      _resizeObserver.observe(document.body);
    } else {
      document.addEventListener("DOMContentLoaded", function() {
        _resizeObserver.observe(document.body);
      });
    }
  }
  window.addEventListener("message", function(event) {
    var data = event.data;
    if (!data || typeof data !== "object") return;
    if (data.subject === "SPLICE.getState") {
      if (!_doenetRestoreReady) {
        _pendingGetStateRequests.push({ source: event.source, messageId: data.message_id });
      } else {
        respondToGetState(event.source, data.message_id);
      }
      return;
    }
    var isSpliceEvent = data.subject === "SPLICE.sendEvent" || data.subject === "SPLICE.reportScoreAndState";
    if (!isSpliceEvent) return;
    if (data.subject === "SPLICE.reportScoreAndState" && window.RunestoneBase && window.RunestoneBase.__ptxScormHooked) {
      if (data.state && typeof data.score === "number") {
        var reportId = resolveIframeId(event.source);
        if (reportId) {
          var savedEntry = _state.answers[reportId];
          var savedPct = savedEntry && typeof savedEntry.percent === "number" ? savedEntry.percent : null;
          if (data.score > 0 || savedPct === null || data.score >= savedPct) {
            saveDoenetState(reportId, data.state);
          }
        }
      }
      return;
    }
    if (typeof data.score !== "number") return;
    var divId = data.activity_id || "splice-unknown";
    var iframeMatched = false;
    var iframes = document.getElementsByTagName("iframe");
    for (var i = 0; i < iframes.length; i++) {
      if (iframes[i].contentWindow === event.source) {
        iframeMatched = true;
        var container = iframes[i].closest('[data-component="splice"],[data-component="doenet"]');
        if (container && container.id) {
          divId = container.id;
        } else if (iframes[i].id) {
          divId = iframes[i].id;
        }
        break;
      }
    }
    if (!iframeMatched) {
      console.warn(
        "[PTX-SCORM] SPLICE: could not match event.source to any iframe on page.",
        "Using div_id:",
        divId,
        "| iframes on page:",
        iframes.length
      );
    }
    var score = data.score;
    if (score > 1) score = score / 100;
    score = Math.max(0, Math.min(1, score));
    var answer = data.data ? JSON.stringify(data.data) : data.name || "";
    try {
      recordInteraction({
        event: "splice",
        div_id: divId,
        answer,
        percent: score
      });
    } catch (err) {
      console.error("[PTX-SCORM] Error recording SPLICE event:", err);
    }
  });
  function addDoenetBadge(container, saved) {
    var existing = container.querySelector(".ptx-scorm-doenet-badge");
    if (existing) existing.remove();
    var pct = typeof saved.percent === "number" ? saved.percent : null;
    if (pct === null) return;
    var badge = document.createElement("div");
    badge.className = "ptx-scorm-doenet-badge";
    var pctLabel = Math.round(pct * 100) + "%";
    if (pct >= 1) {
      badge.textContent = "\u2713 Previously answered correctly (" + pctLabel + ")";
      badge.style.cssText = "padding:4px 8px;margin-bottom:4px;background:#d4edda;color:#155724;border:1px solid #c3e6cb;border-radius:4px;font-size:0.9em;";
    } else if (pct > 0) {
      badge.textContent = "\u25B6 Previously answered \u2014 score: " + pctLabel;
      badge.style.cssText = "padding:4px 8px;margin-bottom:4px;background:#fff3cd;color:#856404;border:1px solid #ffeeba;border-radius:4px;font-size:0.9em;";
    } else {
      badge.textContent = "\u2717 Previously answered \u2014 no credit earned";
      badge.style.cssText = "padding:4px 8px;margin-bottom:4px;background:#f8d7da;color:#721c24;border:1px solid #f5c6cb;border-radius:4px;font-size:0.9em;";
    }
    container.insertBefore(badge, container.firstChild);
  }
  function addWeBWorKBadge(container, saved) {
    var existing = container.querySelector(".ptx-scorm-ww-badge");
    if (existing) existing.remove();
    var badge = document.createElement("span");
    badge.className = "ptx-scorm-ww-badge";
    var pct = typeof saved.percent === "number" ? saved.percent : null;
    var correct = saved.correct;
    if (correct === true || pct >= 1) {
      badge.textContent = "\u2713";
      badge.style.cssText = "float:right;color:green;font-weight:bold;";
    } else if (correct === false || pct !== null && pct < 1) {
      badge.textContent = "\u2717";
      badge.style.cssText = "float:right;color:#c00;font-weight:bold;";
    } else {
      return;
    }
    var buttons = container.querySelector(".problem-buttons");
    if (buttons) {
      buttons.appendChild(badge);
    } else {
      container.insertBefore(badge, container.firstChild);
    }
  }
  function patchWeBWorKSrcdoc(iframe, html) {
    try {
      var container = iframe.parentElement;
      while (container && !container.dataset.domain) {
        container = container.parentElement;
      }
      if (!container) return html;
      var divId = container.id.replace(/-ww-rs$/, "");
      var saved = _state.answers[divId] || _state.answers[container.id];
      if (!saved || !saved.answer) return html;
      var answerObj;
      try {
        answerObj = JSON.parse(saved.answer);
      } catch (e) {
        return html;
      }
      if (!answerObj || !answerObj.answers) return html;
      var answers = answerObj.answers;
      var keys = Object.keys(answers);
      if (keys.length === 0) return html;
      var doc = new DOMParser().parseFromString(html, "text/html");
      var injected = [];
      keys.forEach(function(k) {
        var input = doc.getElementById(k);
        if (!input) return;
        var cur = input.getAttribute("value");
        if (cur === null || cur === "") {
          input.setAttribute("value", String(answers[k]));
          injected.push(k);
        }
      });
      if (injected.length > 0) {
        html = "<!DOCTYPE html>" + doc.documentElement.outerHTML;
      }
      iframe.addEventListener("load", function() {
        setTimeout(function() {
          try {
            let getMathField = function(inp) {
              if (!MQI) return null;
              if (typeof MQI.MathField === "function") return MQI.MathField(inp);
              if (typeof MQI === "function") return MQI(inp);
              return null;
            };
            var iWin = iframe.contentWindow;
            var iDoc = iframe.contentDocument;
            if (!iWin || !iDoc) return;
            var answerQuills = iWin.answerQuills;
            var MQraw = iWin.MathQuill || iWin.MQ;
            var MQI = MQraw ? typeof MQraw.getInterface === "function" ? MQraw.getInterface(2) : MQraw : null;
            var restored = [];
            keys.forEach(function(k) {
              var val = String(answers[k]);
              var aq = answerQuills && answerQuills[k];
              if (aq) {
                var mqf = aq.mathField || aq.mathfield || aq.mq || aq._mathField;
                if (mqf && typeof mqf.latex === "function") {
                  try {
                    mqf.latex(val);
                    restored.push(k);
                    return;
                  } catch (e) {
                  }
                }
                if (typeof aq.setLatex === "function") {
                  try {
                    aq.setLatex(val);
                    restored.push(k);
                    return;
                  } catch (e) {
                  }
                }
                if (typeof aq.latex === "function") {
                  try {
                    aq.latex(val);
                    restored.push(k);
                    return;
                  } catch (e) {
                  }
                }
              }
              var inp = iDoc.getElementById(k);
              if (!inp) return;
              try {
                var mf = getMathField(inp);
                if (mf && typeof mf.latex === "function") {
                  mf.latex(val);
                  restored.push(k);
                  return;
                }
              } catch (e) {
              }
              inp.value = val;
              inp.dispatchEvent(new Event("input", { bubbles: true }));
              restored.push(k);
            });
            if (restored.length > 0) {
              console.log('[PTX-SCORM] WeBWorK: restored "' + divId + '" (' + restored.join(", ") + ").");
            } else {
              console.warn('[PTX-SCORM] WeBWorK: no answer inputs found for "' + divId + '".');
            }
          } catch (e) {
            console.error("[PTX-SCORM] WeBWorK post-load error:", e);
          }
        }, 150);
      }, { once: true });
      return html;
    } catch (e) {
      console.error("[PTX-SCORM] WeBWorK srcdoc patch error:", e);
      return html;
    }
  }
  function installWeBWorKSrcdocIntercept() {
    var proto = HTMLIFrameElement.prototype;
    var desc = Object.getOwnPropertyDescriptor(proto, "srcdoc");
    if (!desc || !desc.set) {
      console.warn("[PTX-SCORM] Cannot intercept iframe.srcdoc \u2014 descriptor unavailable.");
      return;
    }
    var originalSet = desc.set;
    Object.defineProperty(proto, "srcdoc", {
      configurable: true,
      get: desc.get,
      set: function(html) {
        if (this.classList && this.classList.contains("problem-iframe")) {
          html = patchWeBWorKSrcdoc(this, html);
        }
        originalSet.call(this, html);
      }
    });
    console.log("[PTX-SCORM] WeBWorK srcdoc intercept installed.");
  }
  function handleWeBWorKAjaxResponse(xhr) {
    var responseText = xhr && xhr.responseText;
    if (!responseText) return;
    var data;
    try {
      data = JSON.parse(responseText);
    } catch (e) {
      return;
    }
    if (!data || !data.rh_result || !data.rh_result.answers) return;
    if (!data.inputs_ref) return;
    if (data.inputs_ref.WWcorrectAnsOnly) return;
    var wwId = data.inputs_ref.problemUUID || "";
    if (!wwId) return;
    var divId = wwId.replace(/-ww-rs$/, "");
    var rhAnswers = data.rh_result.answers;
    var keys = Object.keys(rhAnswers);
    if (keys.length === 0) return;
    var totalScore = 0;
    var numCorrect = 0;
    keys.forEach(function(key) {
      var partScore = parseFloat(rhAnswers[key].score) || 0;
      totalScore += partScore;
      if (partScore >= 1) numCorrect++;
    });
    var percent = totalScore / keys.length;
    var answerValues = {};
    var mqAnswerValues = {};
    keys.forEach(function(key) {
      var part = rhAnswers[key];
      var studentAns = data.inputs_ref[key] != null ? data.inputs_ref[key] : part.student_value || part.original_student_ans || "";
      if (key.indexOf("MaThQuIlL_") === 0) {
        mqAnswerValues[key] = studentAns;
      } else {
        answerValues[key] = studentAns;
      }
    });
    var answerObj = { answers: answerValues, mqAnswers: mqAnswerValues };
    var actString = "check:actual:" + numCorrect + ":expected:" + keys.length + ":correct:" + numCorrect + ":count:" + keys.length + ":pct:" + percent.toFixed(4);
    console.log('[PTX-SCORM] WeBWorK AJAX response intercepted \u2014 div_id: "' + divId + '", score: ' + (percent * 100).toFixed(0) + "%");
    try {
      recordInteraction({
        event: "webwork",
        div_id: divId,
        act: actString,
        answer: JSON.stringify(answerObj),
        percent
      });
    } catch (err) {
      console.error("[PTX-SCORM] Error recording WeBWorK event:", err);
    }
  }
  function installWeBWorKAjaxIntercept() {
    var _pendingChecks = [];
    function doInstall() {
      if (!window.jQuery) return false;
      var runestoneLoggedIn = typeof eBookConfig !== "undefined" && eBookConfig.username !== "";
      if (runestoneLoggedIn) {
        console.log("[PTX-SCORM] Runestone login detected \u2014 WeBWorK AJAX intercept skipped.");
        return true;
      }
      jQuery(document).on("ajaxSend", function(event, xhr, settings) {
        try {
          var urlData = settings.data;
          if (typeof urlData !== "string") return;
          var params = new URLSearchParams(urlData);
          if (params.get("answersSubmitted") === "1" && !params.get("WWcorrectAnsOnly")) {
            _pendingChecks.push(xhr);
          } else if (params.get("answersSubmitted") === "0" && params.get("problemUUID")) {
            var problemUUID = params.get("problemUUID");
            var divId = problemUUID.replace(/-ww-rs$/, "");
            var saved = _state.answers[divId] || _state.answers[problemUUID];
            if (saved && saved.answer) {
              try {
                var ansObj = JSON.parse(saved.answer);
                if (ansObj && ansObj.answers) {
                  var ansKeys = Object.keys(ansObj.answers);
                  if (ansKeys.length > 0) {
                    ansKeys.forEach(function(k) {
                      params.set(k, String(ansObj.answers[k]));
                    });
                    settings.data = params.toString();
                    console.log('[PTX-SCORM] WeBWorK init: pre-seeded form for "' + divId + '" \u2014 keys: ' + ansKeys.join(", "));
                  }
                }
              } catch (e) {
              }
            }
          }
        } catch (e) {
        }
      });
      jQuery(document).on("ajaxComplete", function(event, xhr) {
        var checkIdx = _pendingChecks.indexOf(xhr);
        if (checkIdx !== -1) {
          _pendingChecks.splice(checkIdx, 1);
          try {
            handleWeBWorKAjaxResponse(xhr);
          } catch (err) {
            console.error("[PTX-SCORM] Error in WeBWorK AJAX handler:", err);
          }
        }
      });
      console.log("[PTX-SCORM] WeBWorK AJAX intercept registered (check-action only).");
      return true;
    }
    if (!doInstall()) {
      window.addEventListener("load", doInstall);
    }
  }
  function loadRestoreData() {
    if (!_api) return {};
    var initResult = _ver === "2004" ? _api.Initialize("") : _api.LMSInitialize("");
    var err = lastError();
    if (initResult !== "true" && err !== "103") {
      console.warn("[PTX-SCORM] Initialize() failed during restore (error=" + err + ").");
      return {};
    }
    _initialized = true;
    _learnerId = _ver === "2004" ? Get("cmi.learner_id") : Get("cmi.core.student_id");
    var entry = Get(_ver === "2004" ? "cmi.entry" : "cmi.core.entry");
    console.log("[PTX-SCORM] Session entry mode: " + (entry || "(empty \u2014 first visit or LMS omits field)"));
    var raw = Get("cmi.suspend_data");
    if (raw) {
      try {
        var saved = JSON.parse(raw);
        if (typeof saved.correct === "number") _state.correct = saved.correct;
        if (typeof saved.graded === "number") _state.graded = saved.graded;
        if (saved.answers && typeof saved.answers === "object") {
          _state.answers = saved.answers;
        }
      } catch (e) {
        console.warn("[PTX-SCORM] Could not parse suspend_data:", e);
      }
    }
    var lsData = loadFromLocalStorage();
    if (lsData && lsData.answers) {
      var lsCount = Object.keys(lsData.answers).length;
      var sdCount = Object.keys(_state.answers).length;
      if (lsCount > sdCount) {
        if (typeof lsData.correct === "number") _state.correct = lsData.correct;
        if (typeof lsData.graded === "number") _state.graded = lsData.graded;
        _state.answers = lsData.answers;
        console.log("[PTX-SCORM] Using localStorage state (" + lsCount + " answers \u2014 more than suspend_data's " + sdCount + ").");
      }
    }
    var lmsCount = parseInt(Get("cmi.interactions._count") || "0", 10);
    _state.iCount = isNaN(lmsCount) ? 0 : lmsCount;
    var completionKey = _ver === "2004" ? "cmi.completion_status" : "cmi.core.lesson_status";
    var currentStatus = Get(completionKey);
    if (currentStatus === "not attempted" || currentStatus === "unknown" || currentStatus === "") {
      Set(completionKey, "incomplete");
      Commit();
    }
    var map = {};
    var divIds = Object.keys(_state.answers || {});
    divIds.forEach(function(divId) {
      var entry2 = _state.answers[divId];
      var restoreEntry = {
        answer: entry2.answer,
        correct: entry2.correct,
        percent: entry2.percent,
        div_id: divId
      };
      map[divId] = restoreEntry;
      if (divId.indexOf("-ww-rs") === -1) {
        map[divId + "-ww-rs"] = restoreEntry;
      }
    });
    if (_state.graded > 0) {
      var denom = _totalQuestions > 0 ? _totalQuestions : _state.graded;
      var restoredScaled = _state.correct / denom;
      if (_ver === "2004") {
        Set("cmi.score.scaled", restoredScaled.toFixed(4));
        Set("cmi.score.raw", (restoredScaled * 100).toFixed(1));
        Set("cmi.score.min", "0");
        Set("cmi.score.max", "100");
      } else {
        Set("cmi.core.score.raw", (restoredScaled * 100).toFixed(1));
      }
      Set("cmi.suspend_data", JSON.stringify(_state));
      Commit();
      console.log("[PTX-SCORM] Restored score: " + (restoredScaled * 100).toFixed(0) + "%  (" + _state.correct.toFixed(2) + " / " + denom + ")  [" + _state.graded + " answered, " + _totalQuestions + " total]");
    }
    var n = Object.keys(map).length;
    if (n === 0) {
      console.log("[PTX-SCORM] No saved answers found (first visit or no prior submissions).");
    } else {
      console.log("[PTX-SCORM] Loaded " + n + " saved answer(s) for UI restoration.");
    }
    _doenetRestoreReady = true;
    _pendingGetStateRequests.forEach(function(req) {
      respondToGetState(req.source, req.messageId);
    });
    _pendingGetStateRequests = [];
    return map;
  }
  function installRestoreHook(restoreMap) {
    if (!window.RunestoneBase || window.RunestoneBase.__ptxScormRestoreHooked) return;
    var n = Object.keys(restoreMap).length;
    if (n === 0) {
      console.log("[PTX-SCORM] Skipping restore hook (no saved answers).");
      return;
    }
    var originalCheckServer = window.RunestoneBase.prototype.checkServer;
    window.RunestoneBase.prototype.checkServer = function(event, skipSelf) {
      var self = this;
      this.checkServerComplete = new Promise(function(resolve) {
        self.csresolver = resolve;
      });
      var data = restoreMap[this.divid];
      if (data !== void 0 && data.answer) {
        try {
          var restoreData = data;
          var compEl = document.getElementById(this.divid);
          var isWeBWorK = compEl && compEl.getAttribute("data-component") === "webwork";
          if (isWeBWorK && typeof data.answer === "string") {
            try {
              var parsed = JSON.parse(data.answer);
              if (parsed && typeof parsed === "object" && parsed.answers) {
                restoreData = {
                  answer: parsed,
                  correct: data.correct,
                  percent: data.percent,
                  div_id: data.div_id
                };
              }
            } catch (e) {
            }
          }
          this.restoreAnswers(restoreData);
          if (data.correct !== null && data.correct !== void 0) {
            this.correct = data.correct;
          }
          if (data.percent !== null && data.percent !== void 0) {
            this.percent = data.percent;
          }
          if (restoreData.answer) {
            this.answer = restoreData.answer;
          }
          if (typeof this.setLocalStorage === "function") {
            this.setLocalStorage(restoreData);
          }
        } catch (err) {
          console.error('[PTX-SCORM] restoreAnswers failed for "' + this.divid + '":', err);
          return originalCheckServer.call(this, event, skipSelf);
        }
        try {
          if (typeof this.decorateStatus === "function") {
            this.decorateStatus();
          }
        } catch (e) {
        }
        var statusLabel = data.correct === true ? "correct" : data.correct === false ? "incorrect" : "neutral";
        console.log('[PTX-SCORM] Restored "' + this.divid + '" (' + statusLabel + ").");
      } else {
        return originalCheckServer.call(this, event, skipSelf);
      }
      if (typeof this.csresolver === "function") this.csresolver();
    };
    window.RunestoneBase.__ptxScormRestoreHooked = true;
    console.log("[PTX-SCORM] Restore hook installed (" + n + " saved answers available).");
  }
  window.addEventListener("beforeunload", function() {
    if (!_initialized) return;
    var json = JSON.stringify(_state);
    Set("cmi.suspend_data", json);
    Set(_ver === "2004" ? "cmi.exit" : "cmi.core.exit", "suspend");
    Commit();
    saveToLocalStorage();
    console.log("[PTX-SCORM] Page unloading \u2014 state saved. exit=suspend set.");
  });
})();
//# sourceMappingURL=ptx_scorm_events.js.map
