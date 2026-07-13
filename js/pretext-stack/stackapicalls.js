const inputPrefix = 'stackapi_input_';
const feedbackPrefix = 'stackapi_fb_';
const validationPrefix = 'stackapi_val_';
let mathjaxPromise = Promise.resolve();
// const stack_api_url = // This is pulled from the publication file

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

// per-question state, keyed by qprefix: timers, last seed used, qfile/qname
const questionState = {};

function getState(qprefix) {
  if (!questionState[qprefix]) {
    questionState[qprefix] = { timeOutHandler: {}, submitSeed: null, qfile: null, qname: null };
  }
  return questionState[qprefix];
}

// wrap inline/display maths in spans so MathJax knows what to typeset
function wrap_math(content) {
  content = content.replace(/(?<!\\)(\\\(.*?(?<!\\)\\\))/gs, "<span class=\"process-math\">$1</span>");
  return content.replace(/(?<!\\)(\\\[.*?(?<!\\)\\\])/gs, "<span class=\"process-math\">$1</span>");
}

// build the payload the STACK API expects for render/validate/grade calls
async function collectData(qfile, qname, qprefix) {
  let res = "";
  await getQuestionFile(qfile, qname).then((response) => {
    if (response.questionxml != "<quiz>\nnull\n</quiz>") {
      res = {
        questionDefinition: response.questionxml,
        answers: collectAnswer(qprefix),
        seed: response.seed,
        renderInputs: inputPrefix,
        readOnly: false,
      };
    }
  });
  return res;
}

// grab the current answer values, but only from this question's own output
// div — otherwise we'd pick up inputs belonging to other questions on the page
function collectAnswer(qprefix) {
  const outputDiv = document.getElementById(qprefix + 'output');
  const scope = outputDiv || document;
  const inputs = scope.getElementsByTagName('input');
  const textareas = scope.getElementsByTagName('textarea');
  const selects = scope.getElementsByTagName('select');
  let res = {};
  res = processNodes(res, inputs);
  res = processNodes(res, textareas);
  res = processNodes(res, selects);

  const hiddenInputs = scope.querySelectorAll(`input[type="hidden"][name^="${inputPrefix}"]`);
  for (const el of hiddenInputs) {
    if (!el.name) continue;
    const key = el.name.slice(inputPrefix.length);
    // don't clobber a value we already picked up from a real input
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
    if (element.name.indexOf(inputPrefix) === 0 && !element.name.endsWith('_val')) {
      if (element.type === 'checkbox' || element.type === 'radio') {
        if (element.checked) {
          res[element.name.slice(inputPrefix.length)] = element.value;
        }
      } else {
        res[element.name.slice(inputPrefix.length)] = element.value;
      }
    }
    if (element.name.indexOf(inputPrefix) === 0 && element.name.endsWith('_val')) {
      res[element.name.slice(inputPrefix.length)] = element.value;
    }
  }
  return res;
}

// fetch and render a fresh instance of the question into the page
function send(qfile, qname, qprefix) {
  const http = new XMLHttpRequest();
  const url = stack_api_url + '/render';
  http.open("POST", url, true);
  http.setRequestHeader('Content-Type', 'application/json');
  http.onreadystatechange = function () {
    if (http.readyState == 4) {
      try {
        const json = JSON.parse(http.responseText);
        if (json.message) {
          console.log(json);
          document.getElementById(qprefix + "errors").innerText = json.message;
          return;
        } else {
          document.getElementById(qprefix + "errors").innerText = '';
        }
        renameIframeHolders();
        let question = json.questionrender;
        const inputs = json.questioninputs;
        const seed = json.questionseed;

        // remember the seed/qfile/qname for this question so Submit can use them later
        const state = getState(qprefix);
        state.submitSeed = seed;
        state.qfile = qfile;
        state.qname = qname;

        let correctAnswers = '';
        const placeholders = question.matchAll(/\[\[input:([a-zA-Z][a-zA-Z0-9_]*)\]\]/g);
        for (const holder of placeholders) {
          const name = holder[1];
          const input = inputs[name];
          if (!input) continue;
          question = question.replace(`[[input:${name}]]`, input.render);
          // 'empty' class needed so Parson's/drag-drop CSS shows/hides this correctly
          question = question.replace(
            `[[validation:${name}]]`,
            `<span name='${validationPrefix + name}' class='stackinputfeedback empty'></span>`
          );
          question = question.replace(
            /javascript:download\(([^,]+?),([^,]+?)\)/,
            `javascript:download($1,$2, '${qfile}', '${qname}', '${qprefix}', ${seed})`
          );
          question = wrap_math(question);

          // build up the "correct answer" text shown after grading
          if (input.samplesolutionrender && name !== 'remember') {
            correctAnswers += `<p>A correct answer is: `;
            if (input.samplesolutionrender.substring(0, 1) === '<') {
              correctAnswers += input.samplesolutionrender;
            } else {
              correctAnswers += `\\[{${input.samplesolutionrender}}\\]`;
            }
            if (input.samplesolution) {
              let answerOutput = "";
              for (const [sname, solution] of Object.entries(input.samplesolution)) {
                if (!sname.endsWith('_val') &&
                    !(typeof solution === 'string' && solution.startsWith('[[{"used":'))) {
                  answerOutput += `<span class='correct-answer'>${wrap_math(solution.replace(/\n/g, '<br>'))}</span>`;
                }
              }
              if (answerOutput) {
                correctAnswers += `, ${stackstring['api_which_typed']}: ` + answerOutput;
              }
            }
            correctAnswers += '.</p>';
          } else if (name !== 'remember' && input.samplesolution) {
            for (const solution of Object.values(input.samplesolution)) {
              if (input.configuration && input.configuration.options) {
                correctAnswers += `<p class='correct-answer'>${input.configuration.options[solution]}</p>`;
              }
            }
          }
        }

        // swap in real URLs for any plots/images the question references
        for (const [name, file] of Object.entries(json.questionassets)) {
          const plotUrl = getPlotUrl(file);
          question = question.replace(name, plotUrl);
          json.questionsamplesolutiontext = json.questionsamplesolutiontext.replace(name, plotUrl);
          correctAnswers = correctAnswers.replace(name, plotUrl);
        }

        // the API renders cors.php links as relative, which resolve against
        // our localhost server instead of the STACK API — make them absolute
        question = question.replace(
          /(?<![:/])(cors\.php)/g,
          `${stack_api_url}/$1`
        );

        // API-rendered ids (e.g. id="stackapi_input_ans1") aren't aware of
        // which question they belong to, so two questions using an input
        // called "ans1" end up with duplicate ids on the page. Prefix every
        // id/for with this question's qprefix to keep them unique.
        question = question.replace(
          /\b(id|for)=(["'])stackapi_/g,
          `$1=$2${qprefix}stackapi_`
        );

        question = replaceFeedbackTags(question, qprefix);
        const qoutput = document.getElementById(qprefix + 'output');
        qoutput.innerHTML = question;
        document.getElementById(qprefix + 'stackapi_qtext').style.display = 'block';

        // debounce typing — validate 1s after the user stops, per input
        for (const inputName of Object.keys(inputs)) {
          const inputElements = qoutput.querySelectorAll(`[name^="${inputPrefix + inputName}"]`);
          for (const inputElement of inputElements) {
            inputElement.oninput = (event) => {
              const currentTimeout = state.timeOutHandler[event.target.id];
              if (currentTimeout) window.clearTimeout(currentTimeout);
              state.timeOutHandler[event.target.id] = window.setTimeout(
                validate.bind(null, event.target, qfile, qname, qprefix), 1000
              );
            };
          }
        }

        wireSubmitButton(qprefix, qfile, qname);

        let sampleText = json.questionsamplesolutiontext;
        if (sampleText) {
          sampleText = replaceFeedbackTags(sampleText, qprefix);
          document.getElementById(qprefix + 'generalfeedback').innerHTML = wrap_math(sampleText);
        }
        // reset everything to a fresh state for the new question
        document.getElementById(qprefix + 'stackapi_generalfeedback').style.display = 'none';
        document.getElementById(qprefix + 'stackapi_score').style.display = 'none';
        document.getElementById(qprefix + 'stackapi_validity').innerText = '';
        const innerFeedback = document.getElementById(qprefix + 'specificfeedback');
        innerFeedback.innerHTML = '';
        innerFeedback.classList.remove('feedback');
        document.getElementById(qprefix + 'formatcorrectresponse').innerHTML = correctAnswers;
        document.getElementById(qprefix + 'stackapi_correct').style.display = 'none';

        // clear out old iframe/input registrations before building new ones,
        // otherwise reused ids get treated as already-registered and the
        // drag-drop UI never shows up
        if (typeof vle_reset_question_registry === 'function') {
          vle_reset_question_registry(qprefix + 'boundary');
        }
        createIframes(json.iframes);
        runMathJax();
      } catch (e) {
        console.log(e);
        document.getElementById(qprefix + 'errors').innerText = http.responseText;
      }
    }
  };

  collectData(qfile, qname, qprefix).then((data) => {
    if (!data) return;
    delete data.answers; // not needed for a fresh render
    http.send(JSON.stringify(data));
    const questioncontainer = document.getElementById(qprefix + 'stack').parentElement;
    if (questioncontainer.getBoundingClientRect().top < 0) {
      questioncontainer.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  });
}

// (re)wire the submit button after each render. Cloning it first wipes any
// listener from a previous render, so we never end up double-submitting.
function wireSubmitButton(qprefix, qfile, qname) {
  const qtext = document.getElementById(qprefix + 'stackapi_qtext');
  if (!qtext) return;
  const submitbutton = qtext.querySelector('input[type="button"]');
  if (!submitbutton) return;

  const freshButton = submitbutton.cloneNode(true);
  submitbutton.parentNode.replaceChild(freshButton, submitbutton);
  freshButton.addEventListener('click', function () {
    const state = getState(qprefix);
    answer(state.qfile || qfile, state.qname || qname, qprefix, state.submitSeed);
  });
}

// check a single input as the user types, without grading the whole question
function validate(element, qfile, qname, qprefix) {
  const http = new XMLHttpRequest();
  const url = stack_api_url + '/validate';
  http.open("POST", url, true);
  const answerNamePrefixTrim = inputPrefix.length;
  const answerName = element.name.slice(answerNamePrefixTrim).split('_', 1)[0];
  http.setRequestHeader('Content-Type', 'application/json');
  http.onreadystatechange = function () {
    if (http.readyState == 4) {
      try {
        const json = JSON.parse(http.responseText);
        if (json.message) {
          document.getElementById(qprefix + 'errors').innerText = json.message;
          return;
        } else {
          document.getElementById(qprefix + 'errors').innerText = '';
        }
        renameIframeHolders();
        const validationHTML = json.validation;
        const outputDiv = document.getElementById(qprefix + 'output');
        const el = outputDiv
          ? outputDiv.querySelector(`[name="${validationPrefix + answerName}"]`)
          : document.getElementsByName(validationPrefix + answerName)[0];
        if (el) {
          // same cors.php fix as in send(), validation responses can contain it too
          const safeValidHTML = validationHTML
            ? validationHTML.replace(/(?<![:/])(cors\.php)/g, `${stack_api_url}/$1`)
            : validationHTML;
          el.innerHTML = wrap_math(safeValidHTML);
          // toggle empty/validation class so the CSS shows/hides the feedback span
          if (validationHTML) {
            el.classList.remove('empty');
            el.classList.add('validation');
          } else {
            el.classList.remove('validation');
            el.classList.add('empty');
          }
        }
        // no vle_reset_question_registry() here: validate() only patches a single
        // validation span, not the question body, so any other iframe belonging
        // to this question (e.g. a Parsons/drag-and-drop/JSXgraph widget) is still
        // live and must keep its existing registry entries.
        createIframes(json.iframes);
        runMathJax();
      } catch (e) {
        document.getElementById(qprefix + 'errors').innerText = http.responseText;
      }
    }
  };
  collectData(qfile, qname, qprefix).then((data) => {
    if (!data) return;
    data.inputName = answerName;
    http.send(JSON.stringify(data));
  });
}

// submit the question for grading
function answer(qfile, qname, qprefix, seed) {
  const http = new XMLHttpRequest();
  const url = stack_api_url + '/grade';
  http.open("POST", url, true);

  if (!document.getElementById(qprefix + 'output').innerText) return;

  http.setRequestHeader('Content-Type', 'application/json');
  http.onreadystatechange = function () {
    if (http.readyState == 4) {
      try {
        const json = JSON.parse(http.responseText);
        if (json.message) {
          document.getElementById(qprefix + 'errors').innerText = json.message;
          return;
        } else {
          document.getElementById(qprefix + 'errors').innerText = '';
        }
        if (!json.isgradable) {
          document.getElementById(qprefix + 'stackapi_validity').innerText = ' ' + stackstring["api_valid_all_parts"];
          return;
        }
        renameIframeHolders();
        document.getElementById(qprefix + 'score').innerText =
          (json.score * json.scoreweights.total).toFixed(2) +
          ' ' + stackstring["api_out_of"] + ' ' + json.scoreweights.total;
        document.getElementById(qprefix + 'stackapi_score').style.display = 'block';
        document.getElementById(qprefix + 'response_summary').innerText = json.responsesummary;
        document.getElementById(qprefix + 'stackapi_generalfeedback').style.display = 'block';
        document.getElementById(qprefix + 'stackapi_summary').style.display = 'none';

        const feedback = json.prts;
        const specificFeedbackElement = document.getElementById(qprefix + 'specificfeedback');
        if (json.specificfeedback) {
          for (const [name, file] of Object.entries(json.gradingassets)) {
            json.specificfeedback = json.specificfeedback.replace(name, getPlotUrl(file));
          }
          json.specificfeedback = replaceFeedbackTags(json.specificfeedback, qprefix);
          specificFeedbackElement.innerHTML = wrap_math(json.specificfeedback);
          specificFeedbackElement.classList.add('feedback');
        } else {
          specificFeedbackElement.classList.remove('feedback');
        }
        // fill in per-PRT feedback and the marks breakdown for each part
        for (let [name, fb] of Object.entries(feedback)) {
          for (const [fname, file] of Object.entries(json.gradingassets)) {
            fb = fb.replace(fname, getPlotUrl(file));
          }
          const elements = document.getElementsByName(qprefix + feedbackPrefix + name);
          if (elements.length > 0) {
            const element = elements[0];
            if (json.scores[name] !== undefined) {
              fb += `<div>${stackstring['api_marks_sub']}: ${(json.scores[name] * json.scoreweights[name] * json.scoreweights.total).toFixed(2)} / ${(json.scoreweights[name] * json.scoreweights.total).toFixed(2)}.</div>`;
            }
            element.innerHTML = wrap_math(fb);
          }
        }
        // no vle_reset_question_registry() here: answer() only patches feedback/score
        // elements, not the question body, so any other iframe belonging to this
        // question (e.g. a Parsons/drag-and-drop/JSXgraph widget) is still live and
        // must keep its existing registry entries.
        createIframes(json.iframes);
        runMathJax();
      } catch (e) {
        console.log(e);
        document.getElementById(qprefix + 'errors').innerText = http.responseText;
      }
    }
  };

  // clear old feedback before the new grading result comes back
  const specificFeedbackElement = document.getElementById(qprefix + 'specificfeedback');
  specificFeedbackElement.innerHTML = "";
  specificFeedbackElement.classList.remove('feedback');
  document.getElementById(qprefix + 'response_summary').innerText = "";
  document.getElementById(qprefix + 'stackapi_summary').style.display = 'none';
  const inputElements = document.querySelectorAll(`[name^="${qprefix + feedbackPrefix}"]`);
  for (const inputElement of inputElements) {
    inputElement.innerHTML = "";
    inputElement.classList.remove('feedback');
  }
  document.getElementById(qprefix + 'stackapi_score').style.display = 'none';
  document.getElementById(qprefix + 'stackapi_validity').innerText = '';

  collectData(qfile, qname, qprefix).then((data) => {
    if (!data) {
      console.error('collectData returned empty for', qprefix);
      return;
    }
    // use the seed from when the question was rendered, not a new random one
    data.seed = seed;
    http.send(JSON.stringify(data));
  });
}

// download a file attached to the question (e.g. a generated worksheet)
function download(filename, fileid, qfile, qname, qprefix, seed) {
  const http = new XMLHttpRequest();
  const url = stack_api_url + '/download';
  http.open("POST", url, true);
  http.setRequestHeader('Content-Type', 'application/json');
  http.filename = filename;
  http.fileid = fileid;
  http.onreadystatechange = function () {
    if (http.readyState == 4) {
      try {
        const blob = new Blob([http.responseText], { type: 'application/octet-binary', endings: 'native' });
        const selector = CSS.escape(`javascript\:download\(\'${http.filename}\'\, ${http.fileid}\, \'${qfile}\'\, \'${qname}\'\, \'${qprefix}\'\, ${seed}\)`);
        const linkElements = document.querySelectorAll(`a[href^=${selector}]`);
        const link = linkElements[0];
        link.setAttribute('href', URL.createObjectURL(blob));
        link.setAttribute('download', filename);
        link.click();
      } catch (e) {
        document.getElementById('errors').innerText = http.responseText;
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

// rename old iframe holders out of the way so new ones don't collide with them
function renameIframeHolders() {
  for (const iframe of document.querySelectorAll(`[id^=stack-iframe-holder]:not([id$=old])`)) {
    iframe.id = iframe.id + '_old';
  }
}

// build each iframe's srcdoc and hand it off to create_iframe in stackjsvle.js
function createIframes(iframes) {
  for (const iframe of iframes) {
    // STACK API content has relative URLs like cors.php?name=sortable.min.css
    // which, inside a sandboxed srcdoc iframe, resolve against our localhost
    // page instead of the API server. Inject a <base href> and also rewrite
    // any relative src/href directly, since not every browser honours base
    // href for things fetched dynamically by scripts inside the iframe.
    const apiBase = stack_api_url.replace(/\/$/, ''); // no trailing slash
    iframe[1] = iframe[1]
      .replace(
        /<head(\s[^>]*)?>/i,
        (match) => `${match}<base href="${apiBase}/" />`
      )
      .replace(
        /((?:src|href)\s*=\s*["'])(?!https?:\/\/|\/\/|data:|blob:|#|javascript:)([^"']+["'])/gi,
        (match, prefix, rest) => `${prefix}${apiBase}/${rest}`
      );
    create_iframe(...iframe);
  }
}

// turn [[feedback:name]] placeholders into real divs the grader can fill in
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

// load and parse the question's source XML file
async function getQuestionFile(questionURL, questionName) {
  let res = "";
  if (questionURL) {
    await fetch(questionURL)
      .then(r => r.text())
      .then((result) => { res = loadQuestionFromFile(result, questionName); });
  }
  return res;
}

// pull the named STACK question (or the first one) out of the quiz XML
function loadQuestionFromFile(fileContents, questionName) {
  const parser = new DOMParser();
  const xmlDoc = parser.parseFromString(fileContents, "text/xml");
  let thequestion = null;
  let randSeed = "";
  for (const question of xmlDoc.getElementsByTagName("question")) {
    if (question.getAttribute('type').toLowerCase() === 'stack' &&
        (!questionName || question.querySelectorAll("name text")[0].textContent === questionName)) {
      thequestion = question.outerHTML;
      const seeds = question.querySelectorAll('deployedseed');
      if (seeds.length) {
        randSeed = parseInt(seeds[Math.floor(Math.random() * seeds.length)].textContent);
      }
      break;
    }
  }
  return { questionxml: '<quiz>\n' + thequestion + '\n</quiz>', seed: randSeed };
}

function runMathJax() {
  if (window.MathJax && MathJax.typesetPromise) {
    mathjaxPromise = mathjaxPromise.then(() => MathJax.typesetPromise()).catch(err => console.log('MathJax error:', err.message));
  } else if (window.MathJax) {
    MathJax.typeset();
  }
}

// find every STACK question on the page and build its UI shell
function createQuestionBlocks() {
  const questionBlocks = document.getElementsByClassName("que stack");
  let i = 0;
  for (const questionblock of questionBlocks) {
    i++;
    const questionPrefix = "q" + i.toString() + "_";
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
            <h2>${stackstring['generalfeedback']}:</h2>
            <div id="${questionPrefix}generalfeedback" class="feedback"></div>
          </div>
          <h2 id="${questionPrefix}stackapi_score" style="display:none">${stackstring['score']}: <span id="${questionPrefix}score"></span></h2>
          <div id="${questionPrefix}stackapi_summary" class="col-lg-10" style="display:none">
            <h2>${stackstring['api_response']}:</h2>
            <div id="${questionPrefix}response_summary" class="feedback"></div>
          </div>
          <div id="${questionPrefix}stackapi_correct" class="col-lg-10" style="display:none">
            <h2>${stackstring['api_correct']}:</h2>
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

// make section headers clickable to expand/collapse their content
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
  return `${stack_api_url}/plots/${file}`;
}