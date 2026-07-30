const inputPrefix = "stackapi_input_";
const feedbackPrefix = "stackapi_fb_";
const validationPrefix = "stackapi_val_";
let mathjaxPromise = Promise.resolve();
const stackstring = {
  "api_valid_all_parts": "Please enter valid answers for all parts of the question.",
  "api_out_of": "out of",
  "api_marks_sub": "Marks for this submission",
  "api_submit": "Submit Answers",
  "generalfeedback": "General feedback",
  "score": "Score",
  "api_response": "Response summary",
  "api_correct": "Correct answers",
  "api_which_typed": "which can be typed as follows"
};
const questionState = {};
function getState(qprefix) {
  if (!questionState[qprefix]) {
    questionState[qprefix] = { timeOutHandler: {}, submitSeed: null, qfile: null, qname: null };
  }
  return questionState[qprefix];
}
function wrap_math(content) {
  content = content.replace(/(?<!\\)(\\\(.*?(?<!\\)\\\))/gs, '<span class="process-math">$1</span>');
  return content.replace(/(?<!\\)(\\\[.*?(?<!\\)\\\])/gs, '<span class="process-math">$1</span>');
}
async function collectData(qfile, qname, qprefix) {
  let res = "";
  await getQuestionFile(qfile, qname).then((response) => {
    if (response && response.questionDefinition) {
      res = {
        questionDefinition: response.questionDefinition,
        answers: collectAnswer(qprefix),
        seed: response.seed,
        renderInputs: inputPrefix,
        readOnly: false
      };
    }
  });
  return res;
}
function collectAnswer(qprefix) {
  const outputDiv = document.getElementById(qprefix + "output");
  const scope = outputDiv || document;
  const inputs = scope.getElementsByTagName("input");
  const textareas = scope.getElementsByTagName("textarea");
  const selects = scope.getElementsByTagName("select");
  let res = {};
  res = processNodes(res, inputs);
  res = processNodes(res, textareas);
  res = processNodes(res, selects);
  const hiddenInputs = scope.querySelectorAll(`input[type="hidden"][name^="${inputPrefix}"]`);
  for (const el of hiddenInputs) {
    if (!el.name) continue;
    const key = el.name.slice(inputPrefix.length);
    if (!(key in res)) {
      res[key] = el.value;
    }
  }
  return res;
}
function processNodes(res, nodes) {
  for (let i = 0; i < nodes.length; i++) {
    const element = nodes[i];
    if (!element.name) continue;
    if (element.name.indexOf(inputPrefix) === 0 && !element.name.endsWith("_val")) {
      if (element.type === "checkbox" || element.type === "radio") {
        if (element.checked) {
          res[element.name.slice(inputPrefix.length)] = element.value;
        }
      } else {
        res[element.name.slice(inputPrefix.length)] = element.value;
      }
    }
    if (element.name.indexOf(inputPrefix) === 0 && element.name.endsWith("_val")) {
      res[element.name.slice(inputPrefix.length)] = element.value;
    }
  }
  return res;
}
function send(qfile, qname, qprefix) {
  const http = new XMLHttpRequest();
  const url = stack_api_url + "/render";
  http.open("POST", url, true);
  http.setRequestHeader("Content-Type", "application/json");
  http.onreadystatechange = function() {
    if (http.readyState == 4) {
      try {
        const json = JSON.parse(http.responseText);
        if (json.message) {
          console.log(json);
          document.getElementById(qprefix + "errors").innerText = json.message;
          return;
        } else {
          document.getElementById(qprefix + "errors").innerText = "";
        }
        renameIframeHolders();
        let question = json.questionrender;
        const inputs = json.questioninputs;
        const seed = json.questionseed;
        const state = getState(qprefix);
        state.submitSeed = seed;
        state.qfile = qfile;
        state.qname = qname;
        let correctAnswers = "";
        const placeholders = question.matchAll(/\[\[input:([a-zA-Z][a-zA-Z0-9_]*)\]\]/g);
        for (const holder of placeholders) {
          const name = holder[1];
          const input = inputs[name];
          if (!input) continue;
          question = question.replace(`[[input:${name}]]`, input.render);
          question = question.replace(
            `[[validation:${name}]]`,
            `<span name='${validationPrefix + name}' class='stackinputfeedback empty'></span>`
          );
          question = question.replace(
            /javascript:download\(([^,]+?),([^,]+?)\)/,
            `javascript:download($1,$2, '${qfile}', '${qname}', '${qprefix}', ${seed})`
          );
          question = wrap_math(question);
          if (input.samplesolutionrender && name !== "remember") {
            correctAnswers += `<p>A correct answer is: `;
            if (input.samplesolutionrender.substring(0, 1) === "<") {
              correctAnswers += input.samplesolutionrender;
            } else {
              correctAnswers += `\\[{${input.samplesolutionrender}}\\]`;
            }
            if (input.samplesolution) {
              let answerOutput = "";
              for (const [sname, solution] of Object.entries(input.samplesolution)) {
                if (!sname.endsWith("_val") && !(typeof solution === "string" && solution.startsWith('[[{"used":'))) {
                  answerOutput += `<span class='correct-answer'>${wrap_math(solution.replace(/\n/g, "<br>"))}</span>`;
                }
              }
              if (answerOutput) {
                correctAnswers += `, ${stackstring["api_which_typed"]}: ` + answerOutput;
              }
            }
            correctAnswers += ".</p>";
          } else if (name !== "remember" && input.samplesolution) {
            for (const solution of Object.values(input.samplesolution)) {
              if (input.configuration && input.configuration.options) {
                correctAnswers += `<p class='correct-answer'>${input.configuration.options[solution]}</p>`;
              }
            }
          }
        }
        for (const [name, file] of Object.entries(json.questionassets)) {
          const plotUrl = getPlotUrl(file);
          question = question.replace(name, plotUrl);
          json.questionsamplesolutiontext = json.questionsamplesolutiontext.replace(name, plotUrl);
          correctAnswers = correctAnswers.replace(name, plotUrl);
        }
        question = question.replace(
          /(?<![:/])(cors\.php)/g,
          `${stack_api_url}/$1`
        );
        question = question.replace(
          /\b(id|for)=(["'])stackapi_/g,
          `$1=$2${qprefix}stackapi_`
        );
        question = replaceFeedbackTags(question, qprefix);
        const qoutput = document.getElementById(qprefix + "output");
        qoutput.innerHTML = question;
        document.getElementById(qprefix + "stackapi_qtext").style.display = "block";
        for (const inputName of Object.keys(inputs)) {
          const inputElements = qoutput.querySelectorAll(`[name^="${inputPrefix + inputName}"]`);
          for (const inputElement of inputElements) {
            inputElement.oninput = (event) => {
              const currentTimeout = state.timeOutHandler[event.target.id];
              if (currentTimeout) window.clearTimeout(currentTimeout);
              state.timeOutHandler[event.target.id] = window.setTimeout(
                validate.bind(null, event.target, qfile, qname, qprefix),
                1e3
              );
            };
          }
        }
        wireSubmitButton(qprefix, qfile, qname);
        let sampleText = json.questionsamplesolutiontext;
        if (sampleText) {
          sampleText = replaceFeedbackTags(sampleText, qprefix);
          document.getElementById(qprefix + "generalfeedback").innerHTML = wrap_math(sampleText);
        }
        document.getElementById(qprefix + "stackapi_generalfeedback").style.display = "none";
        document.getElementById(qprefix + "stackapi_score").style.display = "none";
        document.getElementById(qprefix + "stackapi_validity").innerText = "";
        const innerFeedback = document.getElementById(qprefix + "specificfeedback");
        innerFeedback.innerHTML = "";
        innerFeedback.classList.remove("feedback");
        document.getElementById(qprefix + "formatcorrectresponse").innerHTML = correctAnswers;
        document.getElementById(qprefix + "stackapi_correct").style.display = "none";
        if (typeof vle_reset_question_registry === "function") {
          vle_reset_question_registry(qprefix + "boundary");
        }
        createIframes(json.iframes);
        runMathJax();
      } catch (e) {
        console.log(e);
        document.getElementById(qprefix + "errors").innerText = http.responseText;
      }
    }
  };
  collectData(qfile, qname, qprefix).then((data) => {
    if (!data) return;
    delete data.answers;
    http.send(JSON.stringify(data));
    const questioncontainer = document.getElementById(qprefix + "stack").parentElement;
    if (questioncontainer.getBoundingClientRect().top < 0) {
      questioncontainer.scrollIntoView({ behavior: "smooth", block: "start" });
    }
  });
}
function wireSubmitButton(qprefix, qfile, qname) {
  const qtext = document.getElementById(qprefix + "stackapi_qtext");
  if (!qtext) return;
  const submitbutton = qtext.querySelector('input[type="button"]');
  if (!submitbutton) return;
  const freshButton = submitbutton.cloneNode(true);
  submitbutton.parentNode.replaceChild(freshButton, submitbutton);
  freshButton.addEventListener("click", function() {
    const state = getState(qprefix);
    answer(state.qfile || qfile, state.qname || qname, qprefix, state.submitSeed);
  });
}
function validate(element, qfile, qname, qprefix) {
  const http = new XMLHttpRequest();
  const url = stack_api_url + "/validate";
  http.open("POST", url, true);
  const answerNamePrefixTrim = inputPrefix.length;
  const answerName = element.name.slice(answerNamePrefixTrim).split("_", 1)[0];
  http.setRequestHeader("Content-Type", "application/json");
  http.onreadystatechange = function() {
    if (http.readyState == 4) {
      try {
        const json = JSON.parse(http.responseText);
        if (json.message) {
          document.getElementById(qprefix + "errors").innerText = json.message;
          return;
        } else {
          document.getElementById(qprefix + "errors").innerText = "";
        }
        renameIframeHolders();
        const validationHTML = json.validation;
        const outputDiv = document.getElementById(qprefix + "output");
        const el = outputDiv ? outputDiv.querySelector(`[name="${validationPrefix + answerName}"]`) : document.getElementsByName(validationPrefix + answerName)[0];
        if (el) {
          const safeValidHTML = validationHTML ? validationHTML.replace(/(?<![:/])(cors\.php)/g, `${stack_api_url}/$1`) : validationHTML;
          el.innerHTML = wrap_math(safeValidHTML);
          if (validationHTML) {
            el.classList.remove("empty");
            el.classList.add("validation");
          } else {
            el.classList.remove("validation");
            el.classList.add("empty");
          }
        }
        createIframes(json.iframes);
        runMathJax();
      } catch (e) {
        document.getElementById(qprefix + "errors").innerText = http.responseText;
      }
    }
  };
  collectData(qfile, qname, qprefix).then((data) => {
    if (!data) return;
    data.inputName = answerName;
    data.seed = getState(qprefix).submitSeed;
    http.send(JSON.stringify(data));
  });
}
function answer(qfile, qname, qprefix, seed) {
  const http = new XMLHttpRequest();
  const url = stack_api_url + "/grade";
  http.open("POST", url, true);
  if (!document.getElementById(qprefix + "output").innerText) return;
  http.setRequestHeader("Content-Type", "application/json");
  http.onreadystatechange = function() {
    if (http.readyState == 4) {
      try {
        const json = JSON.parse(http.responseText);
        if (json.message) {
          document.getElementById(qprefix + "errors").innerText = json.message;
          return;
        } else {
          document.getElementById(qprefix + "errors").innerText = "";
        }
        if (!json.isgradable) {
          document.getElementById(qprefix + "stackapi_validity").innerText = " " + stackstring["api_valid_all_parts"];
          return;
        }
        renameIframeHolders();
        document.getElementById(qprefix + "score").innerText = (json.score * json.scoreweights.total).toFixed(2) + " " + stackstring["api_out_of"] + " " + json.scoreweights.total;
        document.getElementById(qprefix + "stackapi_score").style.display = "block";
        document.getElementById(qprefix + "response_summary").innerText = json.responsesummary;
        document.getElementById(qprefix + "stackapi_generalfeedback").style.display = "block";
        document.getElementById(qprefix + "stackapi_summary").style.display = "none";
        const feedback = json.prts;
        const specificFeedbackElement2 = document.getElementById(qprefix + "specificfeedback");
        if (json.specificfeedback) {
          for (const [name, file] of Object.entries(json.gradingassets)) {
            json.specificfeedback = json.specificfeedback.replace(name, getPlotUrl(file));
          }
          json.specificfeedback = replaceFeedbackTags(json.specificfeedback, qprefix);
          specificFeedbackElement2.innerHTML = wrap_math(json.specificfeedback);
          specificFeedbackElement2.classList.add("feedback");
        } else {
          specificFeedbackElement2.classList.remove("feedback");
        }
        for (let [name, fb] of Object.entries(feedback)) {
          for (const [fname, file] of Object.entries(json.gradingassets)) {
            fb = fb.replace(fname, getPlotUrl(file));
          }
          const elements = document.getElementsByName(qprefix + feedbackPrefix + name);
          if (elements.length > 0) {
            const element = elements[0];
            if (json.scores[name] !== void 0) {
              fb += `<div>${stackstring["api_marks_sub"]}: ${(json.scores[name] * json.scoreweights[name] * json.scoreweights.total).toFixed(2)} / ${(json.scoreweights[name] * json.scoreweights.total).toFixed(2)}.</div>`;
            }
            element.innerHTML = wrap_math(fb);
          }
        }
        createIframes(json.iframes);
        runMathJax();
      } catch (e) {
        console.log(e);
        document.getElementById(qprefix + "errors").innerText = http.responseText;
      }
    }
  };
  const specificFeedbackElement = document.getElementById(qprefix + "specificfeedback");
  specificFeedbackElement.innerHTML = "";
  specificFeedbackElement.classList.remove("feedback");
  document.getElementById(qprefix + "response_summary").innerText = "";
  document.getElementById(qprefix + "stackapi_summary").style.display = "none";
  const inputElements = document.querySelectorAll(`[name^="${qprefix + feedbackPrefix}"]`);
  for (const inputElement of inputElements) {
    inputElement.innerHTML = "";
    inputElement.classList.remove("feedback");
  }
  document.getElementById(qprefix + "stackapi_score").style.display = "none";
  document.getElementById(qprefix + "stackapi_validity").innerText = "";
  collectData(qfile, qname, qprefix).then((data) => {
    if (!data) {
      console.error("collectData returned empty for", qprefix);
      return;
    }
    data.seed = seed;
    http.send(JSON.stringify(data));
  });
}
function download(filename, fileid, qfile, qname, qprefix, seed) {
  const http = new XMLHttpRequest();
  const url = stack_api_url + "/download";
  http.open("POST", url, true);
  http.setRequestHeader("Content-Type", "application/json");
  http.filename = filename;
  http.fileid = fileid;
  http.onreadystatechange = function() {
    if (http.readyState == 4) {
      try {
        const blob = new Blob([http.responseText], { type: "application/octet-binary", endings: "native" });
        const selector = CSS.escape(`javascript:download('${http.filename}', ${http.fileid}, '${qfile}', '${qname}', '${qprefix}', ${seed})`);
        const linkElements = document.querySelectorAll(`a[href^=${selector}]`);
        const link = linkElements[0];
        link.setAttribute("href", URL.createObjectURL(blob));
        link.setAttribute("download", filename);
        link.click();
      } catch (e) {
        document.getElementById("errors").innerText = http.responseText;
      }
    }
  };
  collectData(qfile, qname, qprefix).then((data) => {
    if (!data) return;
    data.filename = filename;
    data.fileid = fileid;
    data.seed = seed;
    http.send(JSON.stringify(data));
  });
}
function renameIframeHolders() {
  for (const iframe of document.querySelectorAll(`[id^=stack-iframe-holder]:not([id$=old])`)) {
    iframe.id = iframe.id + "_old";
  }
}
function createIframes(iframes) {
  for (const iframe of iframes) {
    const apiBase = stack_api_url.replace(/\/$/, "");
    iframe[1] = iframe[1].replace(
      /<head(\s[^>]*)?>/i,
      (match) => `${match}<base href="${apiBase}/" />`
    ).replace(
      /((?:src|href)\s*=\s*["'])(?!https?:\/\/|\/\/|data:|blob:|#|javascript:)([^"']+["'])/gi,
      (match, prefix, rest) => `${prefix}${apiBase}/${rest}`
    );
    create_iframe(...iframe);
  }
}
function replaceFeedbackTags(text, qprefix) {
  let result = text;
  const feedbackTags = text.match(/\[\[feedback:.*?\]\]/g);
  if (feedbackTags) {
    for (const tag of feedbackTags) {
      result = result.replace(tag, `<div name='${qprefix + feedbackPrefix + tag.slice(11, -2)}'></div>`);
    }
  }
  return result;
}
async function getQuestionFile(questionURL, questionName) {
  let res = "";
  if (questionURL) {
    await fetch(questionURL).then((r) => r.text()).then((result) => {
      res = /\.ya?ml$/i.test(questionURL) ? loadQuestionFromYaml(result) : loadQuestionFromXml(result, questionName);
    });
  }
  return res;
}
function loadQuestionFromXml(fileContents, questionName) {
  const parser = new DOMParser();
  const xmlDoc = parser.parseFromString(fileContents, "text/xml");
  for (const question of xmlDoc.getElementsByTagName("question")) {
    if (question.getAttribute("type").toLowerCase() === "stack" && (!questionName || question.querySelectorAll("name text")[0].textContent === questionName)) {
      let randSeed = "";
      const seeds = question.querySelectorAll("deployedseed");
      if (seeds.length) {
        randSeed = parseInt(seeds[Math.floor(Math.random() * seeds.length)].textContent);
      }
      return { questionDefinition: "<quiz>\n" + question.outerHTML + "\n</quiz>", seed: randSeed };
    }
  }
  return { questionDefinition: null, seed: "" };
}
function loadQuestionFromYaml(fileContents) {
  let randSeed = "";
  const lines = fileContents.split(/\r?\n/);
  const headerIndex = lines.findIndex((line) => /^deployedseed:\s*(\[.*\])?\s*$/.test(line));
  if (headerIndex !== -1) {
    const seeds = [];
    const flowStyle = lines[headerIndex].match(/\[(.*)\]/);
    if (flowStyle) {
      for (const item of flowStyle[1].split(",")) {
        const value = item.trim().replace(/^['"]|['"]$/g, "");
        if (value) seeds.push(value);
      }
    } else {
      for (let i = headerIndex + 1; i < lines.length; i++) {
        const item = lines[i].match(/^\s+-\s*['"]?(-?\d+)['"]?\s*$/);
        if (!item) break;
        seeds.push(item[1]);
      }
    }
    if (seeds.length) {
      randSeed = parseInt(seeds[Math.floor(Math.random() * seeds.length)]);
    }
  }
  return { questionDefinition: fileContents, seed: randSeed };
}
function runMathJax() {
  if (window.MathJax && MathJax.typesetPromise) {
    mathjaxPromise = mathjaxPromise.then(() => MathJax.typesetPromise()).catch((err) => console.log("MathJax error:", err.message));
  } else if (window.MathJax) {
    MathJax.typeset();
  }
}
function createQuestionBlocks() {
  const questionBlocks = document.getElementsByClassName("que stack");
  for (const questionblock of questionBlocks) {
    const questionPrefix = questionblock.id + "_";
    const qfile = questionblock.dataset.qfile;
    const qname = questionblock.dataset.qname || "";
    questionblock.id = questionPrefix + "boundary";
    questionblock.innerHTML = `
      <div class="collapsiblecontent" id="${questionPrefix}stack">
        <div class="vstack gap-3 ms-3 col-lg-8">
          <div id="${questionPrefix}errors"></div>
          <div id="${questionPrefix}stackapi_qtext" class="col-lg-8" style="display:none">
            <div id="${questionPrefix}output" class="formulation"></div>
            <div id="${questionPrefix}specificfeedback"></div>
            <br>
            <input type="button" class="btn btn-primary" value="${stackstring["api_submit"]}"/>
            <span id="${questionPrefix}stackapi_validity" style="color:darkred"></span>
          </div>
          <div id="${questionPrefix}stackapi_generalfeedback" class="col-lg-8" style="display:none">
            <h2>${stackstring["generalfeedback"]}:</h2>
            <div id="${questionPrefix}generalfeedback" class="feedback"></div>
          </div>
          <h2 id="${questionPrefix}stackapi_score" style="display:none">${stackstring["score"]}: <span id="${questionPrefix}score"></span></h2>
          <div id="${questionPrefix}stackapi_summary" class="col-lg-10" style="display:none">
            <h2>${stackstring["api_response"]}:</h2>
            <div id="${questionPrefix}response_summary" class="feedback"></div>
          </div>
          <div id="${questionPrefix}stackapi_correct" class="col-lg-10" style="display:none">
            <h2>${stackstring["api_correct"]}:</h2>
            <div id="${questionPrefix}formatcorrectresponse" class="feedback"></div>
          </div>
        </div>
        <div id="${questionPrefix}newquestionbutton">
          <input type="button"
            onclick="send('${qfile}', '${qname}', '${questionPrefix}')"
            class="btn btn-primary"
            value="Show new example question"/>
        </div>
      </div>`;
  }
}
function addCollapsibles() {
  const collapsibles = document.querySelectorAll(".level2>h2, .stack>h2");
  for (let i = 0; i < collapsibles.length; i++) {
    collapsibles[i].addEventListener("click", () => collapseFunc(collapsibles[i]));
  }
}
function collapseFunc(e) {
  e.classList.toggle("collapsed");
}
function stackSetup() {
  createQuestionBlocks();
  addCollapsibles();
}
function getPlotUrl(file) {
  return `${stack_api_url}/plot.php/${file}`;
}
document.addEventListener("error", (event) => {
  const el = event.target;
  if (el.tagName === "IMG" && el.src.includes("/plot.php/")) {
    el.src = el.src.replace("/plot.php/", "/plots/");
  }
}, true);
//# sourceMappingURL=stackapicalls.js.map
