const timeOutHandler = new Object();
const inputPrefix = 'stackapi_input_';
const feedbackPrefix = 'stackapi_fb_';
const validationPrefix = 'stackapi_val_';
// const stack_api_url = // This is pulled from the publication file

const stackstring = {
  "teacheranswershow_mcq":"A correct answer is: {$a->display}",
  "api_which_typed":"which can be typed as follows",
  "api_valid_all_parts":"Please enter valid answers for all parts of the question.",
  "api_out_of":"out of",
  "api_marks_sub":"Marks for this submission",
  "api_submit":"Submit Answers",
  "generalfeedback":"General feedback",
  "score":"Score",
  "api_response":"Response summary",
  "api_correct":"Correct answers"
};

// Create data for call to API.
async function collectData(qfile, qname, qprefix) {
  let res = "";

    await getQuestionFile(qfile, qname).then((response)=>{
      if (response.questionxml != "<quiz>\nnull\n</quiz>") {
        res = {
          questionDefinition: response.questionxml,
          answers: collectAnswer(qprefix),
          seed: response.seed,
          renderInputs: qprefix + inputPrefix,
          readOnly: false,
        };
      };
    });
  // }
  return res;
}

// Get the different input elements by tag and return object with values.
function collectAnswer(qprefix) {
  const inputs = document.getElementsByTagName('input');
  const textareas = document.getElementsByTagName('textarea');
  const selects = document.getElementsByTagName('select');
  let res = {};
  res = processNodes(res, inputs, qprefix);
  res = processNodes(res, textareas, qprefix);
  res = processNodes(res, selects, qprefix);
  return res;
}

// Return object of values of valid entries in an HTMLCollection.
function processNodes(res, nodes, qprefix) {
  for (let i = 0; i < nodes.length; i++) {
    const element = nodes[i];
    if (element.name.indexOf(qprefix+inputPrefix) === 0 && element.name.indexOf('_val') === -1) {
      if (element.type === 'checkbox' || element.type === 'radio') {
        if (element.checked) {
          res[element.name.slice((qprefix+inputPrefix).length)] = element.value;
        }
      } else {
        res[element.name.slice((qprefix+inputPrefix).length)] = element.value;
      }
    }
  }
  return res;
}

// Display rendered question and solution.
function send(qfile, qname, qprefix) {
  const http = new XMLHttpRequest();
  const url = stack_api_url + '/render';
  http.open("POST", url, true);
  http.setRequestHeader('Content-Type', 'application/json');
  http.onreadystatechange = function() {
    if(http.readyState == 4) {
      try {
        const json = JSON.parse(http.responseText);
        if (json.message) {
          console.log(json);
          document.getElementById(`${qprefix+"errors"}`).innerText = json.message;
          return;
        } else {
          document.getElementById(`${qprefix+"errors"}`).innerText = '';
        }
        renameIframeHolders();
        let question = json.questionrender;
        const inputs = json.questioninputs;
        const seed = json.questionseed;
        let correctAnswers = '';
        // Show correct answers.
        for (const [name, input] of Object.entries(inputs)) {
          question = question.replace(`[[input:${name}]]`, input.render);
          // question = question.replaceAll(`${inputPrefix}`,`${qprefix+inputPrefix}`);
          question = question.replace(`[[validation:${name}]]`, `<span name='${qprefix+validationPrefix + name}'></span>`);
          // This is a bit of a hack. The question render returns an <a href="..."> calling the download function with
          // two arguments. We add the additional arguments that we need for context (question definition) here.
          question = question.replace(/javascript:download\(([^,]+?),([^,]+?)\)/, `javascript:download($1,$2, '${qfile}', '${qname}', '${qprefix}', ${seed})`);
          if (input.samplesolutionrender && name !== 'remember') {
            // Display render of answer and matching user input to produce the answer.
            correctAnswers += `<p>
                  ${stackstring['teacheranswershow_mcq']} \\[{${input.samplesolutionrender}}\\],
                  ${stackstring['api_which_typed']}: `;
            for (const [name, solution] of Object.entries(input.samplesolution)) {
              if (name.indexOf('_val') === -1) {
                correctAnswers += `<span class='correct-answer'>${solution}</span>`;
              }
            }
            correctAnswers += '.</p>';
          } else if (name !== 'remember') {
            // For dropdowns, radio buttons, etc, only the correct option is displayed.
            for (const solution of Object.values(input.samplesolution)) {
              if (input.configuration.options) {
                correctAnswers += `<p class='correct-answer'>${input.configuration.options[solution]}</p>`;
              }
            }
          }
        }
        // Convert Moodle plot filenames to API filenames.
        for (const [name, file] of Object.entries(json.questionassets)) {
          const plotUrl = getPlotUrl(file);
          question = question.replace(name, plotUrl);
          json.questionsamplesolutiontext = json.questionsamplesolutiontext.replace(name, plotUrl);
          correctAnswers = correctAnswers.replace(name, plotUrl);
        }

        question = replaceFeedbackTags(question,qprefix);
        qoutput = document.getElementById(`${qprefix+'output'}`);
        qoutput.innerHTML = question;
        // Only display results sections once question retrieved.
        document.getElementById(`${qprefix+'stackapi_qtext'}`).style.display = 'block';
        document.getElementById(`${qprefix+'stackapi_correct'}`).style.display = 'block';

        // Setup a validation call on inputs. Timeout length is reset if the input is updated
        // before the validation call is made.
        for (const inputName of Object.keys(inputs)) {
          const inputElements = document.querySelectorAll(`[name^=${qprefix+inputPrefix + inputName}]`);
          for (const inputElement of Object.values(inputElements)) {
            inputElement.oninput = (event) => {
              const currentTimeout = timeOutHandler[event.target.id];
              if (currentTimeout) {
                window.clearTimeout(currentTimeout);
              }
              timeOutHandler[event.target.id] = window.setTimeout(validate.bind(null, event.target, qfile, qname, qprefix), 1000);
            };
          }
        }
        let sampleText = json.questionsamplesolutiontext;
        if (sampleText) {
          sampleText = replaceFeedbackTags(sampleText,qprefix);
          document.getElementById(`${qprefix+'generalfeedback'}`).innerHTML = sampleText;
          document.getElementById(`${qprefix+'stackapi_generalfeedback'}`).style.display = 'block';
        } else {
          // If the question is updated, there may no longer be general feedback.
          document.getElementById(`${qprefix+'stackapi_generalfeedback'}`).style.display = 'none';
        }
        document.getElementById(`${qprefix+'stackapi_score'}`).style.display = 'none';
        document.getElementById(`${qprefix+'stackapi_validity'}`).innerText = '';
        const innerFeedback = document.getElementById(`${qprefix+'specificfeedback'}`);
        innerFeedback.innerHTML = '';
        innerFeedback.classList.remove('feedback');
        document.getElementById(`${qprefix+'formatcorrectresponse'}`).innerHTML = correctAnswers;

        // Hide General feedback and correct answers for now
        document.getElementById(`${qprefix+'stackapi_generalfeedback'}`).style.display = 'none';
        document.getElementById(`${qprefix+'stackapi_correct'}`).style.display = 'none';

        createIframes(json.iframes);
        MathJax.Hub.Queue(["Typeset", MathJax.Hub]);
      }
      catch(e) {
        console.log(e);
        document.getElementById(`${qprefix+'errors'}`).innerText = http.responseText;
        return;
      }
    }
  };
  collectData(qfile, qname, qprefix).then((data)=>{
    let submitbutton = document.getElementById(`${qprefix + 'stackapi_qtext'}`).querySelector('input[type="button"]');
    submitbutton.addEventListener('click', function() {answer(qfile, qname, qprefix, data.seed)});
    http.send(JSON.stringify(data));
    let questioncontainer = document.getElementById(`${qprefix+'stack'}`).parentElement;
    if (questioncontainer.getBoundingClientRect().top<0){
      questioncontainer.scrollIntoView({ behavior: 'smooth', block: 'start' });
    };
  });
}

// Validate an input. Called a set amount of time after an input is last updated.
function validate(element, qfile, qname, qprefix) {
  const http = new XMLHttpRequest();
  const url = stack_api_url + '/validate';
  http.open("POST", url, true);
  // Remove API prefix and subanswer id.
  const answerNamePrefixTrim = (qprefix+inputPrefix).length;
  const answerName = element.name.slice(answerNamePrefixTrim).split('_', 1)[0];
  http.setRequestHeader('Content-Type', 'application/json');
  http.onreadystatechange = function() {
    if(http.readyState == 4) {
      try {
        const json = JSON.parse(http.responseText);
        if (json.message) {
          document.getElementById(`${qprefix+'errors'}`).innerText = json.message;
          return;
        } else {
          document.getElementById(`${qprefix+'errors'}`).innerText = '';
        }
        renameIframeHolders();
        const validationHTML = json.validation;
        const element = document.getElementsByName(`${qprefix+validationPrefix + answerName}`)[0];
        element.innerHTML = validationHTML;
        if (validationHTML) {
          element.classList.add('validation');
        } else {
          element.classList.remove('validation');
        }
        createIframes(json.iframes);
        MathJax.Hub.Queue(["Typeset", MathJax.Hub]);
      }
      catch(e) {
        document.getElementById(`${qprefix+'errors'}`).innerText = http.responseText;
        return;
      }
    }
  };
  collectData(qfile, qname, qprefix).then((data)=>{
    data.inputName = answerName;
    http.send(JSON.stringify(data));
  });
}

// Submit answers.
function answer(qfile, qname, qprefix, seed) {
  const http = new XMLHttpRequest();
  const url = stack_api_url + '/grade';
  http.open("POST", url, true);

  if (!document.getElementById(`${qprefix+'output'}`).innerText) {
    return;
  }

  http.setRequestHeader('Content-Type', 'application/json');
  http.onreadystatechange = function() {
    if(http.readyState == 4) {
      try {
        const json = JSON.parse(http.responseText);
        if (json.message) {
          document.getElementById(`${qprefix+'errors'}`).innerText = json.message;
          return;
        } else {
          document.getElementById(`${qprefix+'errors'}`).innerText = '';
        }
        if (!json.isgradable) {
          document.getElementById(`${qprefix+'stackapi_validity'}`).innerText
              = ' ' + stackstring["api_valid_all_parts"];
          return;
        }
        renameIframeHolders();
        document.getElementById(`${qprefix+'score'}`).innerText
            = (json.score * json.scoreweights.total).toFixed(2) +
            ' ' + stackstring["api_out_of"] + ' ' + json.scoreweights.total;
        document.getElementById(`${qprefix+'stackapi_score'}`).style.display = 'block';
        document.getElementById(`${qprefix+'response_summary'}`).innerText = json.responsesummary;

        // Show General feedback and correct answers, hide summary
        document.getElementById(`${qprefix+'stackapi_generalfeedback'}`).style.display = 'block';

        document.getElementById(`${qprefix+'stackapi_summary'}`).style.display = 'none';

        const feedback = json.prts;
        const specificFeedbackElement = document.getElementById(`${qprefix+'specificfeedback'}`);
        // Replace tags and plots in specific feedback and then display.
        if (json.specificfeedback) {
          for (const [name, file] of Object.entries(json.gradingassets)) {
            json.specificfeedback = json.specificfeedback.replace(name, getPlotUrl(file));
          }
          json.specificfeedback = replaceFeedbackTags(json.specificfeedback,qprefix);
          specificFeedbackElement.innerHTML = json.specificfeedback;
          specificFeedbackElement.classList.add('feedback');
        } else {
          specificFeedbackElement.classList.remove('feedback');
        }
        // Replace plots in tagged feedback and then display.
        for (let [name, fb] of Object.entries(feedback)) {
          for (const [name, file] of Object.entries(json.gradingassets)) {
            fb = fb.replace(name, getPlotUrl(file));
          }
          const elements = document.getElementsByName(`${qprefix+feedbackPrefix + name}`);
          if (elements.length > 0) {
            const element = elements[0];
            if (json.scores[name] !== undefined) {
              fb = fb + `<div>${stackstring['api_marks_sub']}:
                    ${(json.scores[name] * json.scoreweights[name] * json.scoreweights.total).toFixed(2)}
                      / ${(json.scoreweights[name] * json.scoreweights.total).toFixed(2)}.</div>`;
            }
            element.innerHTML = fb;
            // if (fb) {
//                   element.classList.add('feedback');
//                 } else {
//                   element.classList.remove('feedback');
//                 }
          }
        }
        createIframes(json.iframes);
        MathJax.Hub.Queue(["Typeset", MathJax.Hub]);
      }
      catch(e) {
        console.log(e);
        document.getElementById(`${qprefix+'errors'}`).innerText = http.responseText;
        return;
      }
    }
  };
  // Clear previous answers and score.
  const specificFeedbackElement = document.getElementById(`${qprefix+'specificfeedback'}`);
  specificFeedbackElement.innerHTML = "";
  specificFeedbackElement.classList.remove('feedback');
  document.getElementById(`${qprefix+'response_summary'}`).innerText = "";
  document.getElementById(`${qprefix+'stackapi_summary'}`).style.display = 'none';
  const inputElements = document.querySelectorAll(`[name^=${qprefix+feedbackPrefix}]`);
  for (const inputElement of Object.values(inputElements)) {
    inputElement.innerHTML = "";
    inputElement.classList.remove('feedback');
  }
  document.getElementById(`${qprefix+'stackapi_score'}`).style.display = 'none';
  document.getElementById(`${qprefix+'stackapi_validity'}`).innerText = '';
  collectData(qfile, qname, qprefix).then((data) => {
    data.seed = seed;
    http.send(JSON.stringify(data));
  });
}

function download(filename, fileid, qfile, qname, qprefix, seed) {
  const http = new XMLHttpRequest();
  const url = stack_api_url + '/download';
  http.open("POST", url, true);
  http.setRequestHeader('Content-Type', 'application/json');
  // Something funky going on with closures and callbacks. This seems
  // to be the easiest way to pass through the file details.
  http.filename = filename;
  http.fileid = fileid;
  http.onreadystatechange = function() {
    if(http.readyState == 4) {
      try {
        // Only download the file once. Replace call to download controller with link
        // to downloaded file.
        const blob = new Blob([http.responseText], {type: 'application/octet-binary', endings: 'native'});
        // We're matching the three additional arguments that are added in the send function here.
        const selector = CSS.escape(`javascript\:download\(\'${http.filename}\'\, ${http.fileid}\, \'${qfile}\'\, \'${qname}\'\, \'${qprefix}\'\, ${seed}\)`);
        const linkElements = document.querySelectorAll(`a[href^=${selector}]`);
        const link = linkElements[0];
        link.setAttribute('href', URL.createObjectURL(blob));
        link.setAttribute('download', filename);
        link.click();
      }
      catch(e) {
        document.getElementById('errors').innerText = http.responseText;
        return;
      }
    }
  };
  collectData(qfile, qname, qprefix).then((data)=>{
    data.filename = filename;
    data.fileid = fileid;
    data.seed = seed;
    http.send(JSON.stringify(data));
  });
}

// Save contents of question editor locally.
function saveState(key, value) {
  if (typeof(Storage) !== "undefined") {
    localStorage.setItem(key, value);
  }
}

// Load locally stored question on page refresh.
function loadState(key) {
  if (typeof(Storage) !== "undefined") {
    return localStorage.getItem(key) || '';
  }
  return '';
}

function renameIframeHolders() {
  // Each call to STACK restarts numbering of iframe holders so we need to rename
  // any old ones to make sure new iframes end up in the correct place.
  for (const iframe of document.querySelectorAll(`[id^=stack-iframe-holder]:not([id$=old]`)) {
    iframe.id = iframe.id + '_old';
  }
}

function createIframes (iframes) {
  const corsFragment = "/cors.php?name=";

  for (const iframe of iframes) {
    create_iframe(
      iframe[0],
      iframe[1].replaceAll(corsFragment, stack_api_url + corsFragment),
      ...iframe.slice(2)
    );
  }
}

// Replace feedback tags in some text with an approproately named HTML div.
function replaceFeedbackTags(text, qprefix) {
  let result = text;
  const feedbackTags = text.match(/\[\[feedback:.*?\]\]/g);
  if (feedbackTags) {
    for (const tag of feedbackTags) {
      // Part name is between '[[feedback:' and ']]'.
      result = result.replace(tag, `<div name='${qprefix+feedbackPrefix + tag.slice(11, -2)}'></div>`);
    }
  }
  return result;
}

async function getQuestionFile(questionURL, questionName) {
  let res = "";
  if (questionURL) {
    await fetch(questionURL)
        .then(result => result.text())
        .then((result) => {
          res = loadQuestionFromFile(result, questionName);
        });
  }
  return res;
}

function loadQuestionFromFile(fileContents, questionName) {
  const parser = new DOMParser();
  const xmlDoc = parser.parseFromString(fileContents, "text/xml");

  let thequestion = null;
  let randSeed = "";
  for (const question of xmlDoc.getElementsByTagName("question")) {
    if (question.getAttribute('type').toLowerCase() === 'stack' && (!questionName || question.querySelectorAll("name text")[0].textContent === questionName)) {
      thequestion = question.outerHTML;
      let seeds = question.querySelectorAll('deployedseed');
      if (seeds.length) {
        randSeed = parseInt(seeds[Math.floor(Math.random()*seeds.length)].textContent);
      }
      break;
    }
  }
  return {questionxml:setQuestion(thequestion),seed:randSeed};
}

function setQuestion(question) {
  return '<quiz>\n' + question + '\n</quiz>';
}

function createQuestionBlocks() {
  questionBlocks = document.getElementsByClassName("que stack");
  let i=0;

  for (questionblock of questionBlocks){
    i++;
    let questionPrefix = "q" + i.toString() + "_";
    var qfile = questionblock.dataset.qfile;
    var qname = questionblock.dataset.qname || "";
    questionblock.innerHTML =
        `
                <div class="collapsiblecontent" id=${questionPrefix + "stack"}>
                    <div class="vstack gap-3 ms-3 col-lg-8">
                        <div id=${questionPrefix + "errors"}></div>
                        <div id=${questionPrefix + "stackapi_qtext"} class="col-lg-8" style="display: none">
                          <!--<h2>${stackstring['questiontext']}:</h2>-->
                          <div id=${questionPrefix + "output"} class="formulation"></div>
                          <div id=${questionPrefix + "specificfeedback"}></div>
                          <br>
                          <!-- <input type="button" onclick="answer('${qfile}', '${qname}', '${questionPrefix}')" class="btn btn-primary" value=${stackstring["api_submit"]}/>-->
                          <input type="button" class="btn btn-primary" value=${stackstring["api_submit"]}/>
                          <span id=${questionPrefix + "stackapi_validity"} style="color:darkred"></span>
                        </div>
                        <div id=${questionPrefix + "stackapi_generalfeedback"} class="col-lg-8" style="display: none">
                          <h2>${stackstring['generalfeedback']}:</h2>
                          <div id=${questionPrefix + "generalfeedback"} class="feedback"></div>
                        </div>
                        <h2 id=${questionPrefix + "stackapi_score"} style="display: none">${stackstring['score']}: <span id=${questionPrefix + "score"}></span></h2>
                        <div id=${questionPrefix + "stackapi_summary"} class="col-lg-10" style="display: none">
                          <h2>${stackstring['api_response']}:</h2>
                          <div id=${questionPrefix + "response_summary"} class="feedback"></div>
                        </div>
                        <div id=${questionPrefix + "stackapi_correct"} class="col-lg-10" style="display: none">
                          <h2>${stackstring['api_correct']}:</h2>
                          <div id=${questionPrefix + "formatcorrectresponse"} class="feedback"></div>
                        </div>
                    </div>
                    <div id=${questionPrefix + "newquestionbutton"}>
                      <input type="button" onclick="send('${qfile}', '${qname}', '${questionPrefix}')" class="btn btn-primary" value="Show new example question"/>
                    </div>
                </div>
              `;
  }
}

function addCollapsibles(){
  var collapsibles = document.querySelectorAll(".level2>h2, .stack>h2");
  for (let i=0; i<collapsibles.length; i++) {
    collapsibles[i].addEventListener("click", () => collapseFunc(this));
  }
}

function collapseFunc(e){
  e.classList.toggle("collapsed");
}

function stackSetup(){
  createQuestionBlocks();
  addCollapsibles();
}

function getPlotUrl(file) {
  return `${stack_api_url}/plots/${file}`;
}
