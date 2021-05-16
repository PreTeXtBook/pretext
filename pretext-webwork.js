function initWW(ww_id) {
//Critical:
// TODO: Think about what should be done for an essay question.

//Accessibility:

//Enhancement:
// TODO: In a scaffold problem, adjust the green bar for when one part is correct.
// TODO: Have randomize check that new seed is actually producing new HTML.
// TODO: Don't offer randomize or button unless we know a new version can be produced after trying a few seeds.
// TODO: In a staged problem, Make Interactive button is adjacent to solution knowls; move it.

//Styling:
// TODO: Review all styling in all scenarios (staged/not, correct/partly-correct/incorrect/blank, single/multiple)
// TODO: Sean: I think I'd like to see a slightly larger font size on the buttons

    const ww_container = document.getElementById(ww_id)
    const ww_domain = ww_container.dataset.domain
    let ww_seed = ww_container.dataset.seed
    let ww_problemSource = ww_container.dataset.problemsource
    let ww_sourceFilePath = ww_container.dataset.sourcefilepath
    const ww_course_id = ww_container.dataset.courseid
    const ww_user_id = ww_container.dataset.userid
    const ww_course_password = ww_container.dataset.coursepassword

    let url = new URL(ww_domain + '/webwork2/html2xml')
    url.searchParams.append("problemSeed", ww_seed);
    if (ww_problemSource) {
        url.searchParams.append("problemSource", ww_problemSource);
    } else if (ww_sourceFilePath) {
        url.searchParams.append("sourceFilePath", ww_sourceFilePath);
    }
    url.searchParams.append("answersSubmitted", "0");
    url.searchParams.append("displayMode", "MathJax");
    url.searchParams.append("courseID", ww_course_id);
    url.searchParams.append("userID", ww_user_id);
    url.searchParams.append("course_password", ww_course_password);
    url.searchParams.append("outputformat", "raw");

    // get the json and do stuff with what we get
    $.getJSON(url.toString(), function(data) {
        // append ww_id here for ease of access
        data.ww_id = ww_id
        // a form will contain the text and input fields of the interactive problem
        var form = document.createElement("form")
        form.id = ww_id + "-form"
        form.onsubmit = function () {
            updateWW(ww_id,"check");
            return false;
        }
        // determine if static version shows hints, solutions, answers
        var b_ptx_has_hint = ww_container.getElementsByClassName('hint').length > 0;
        var b_ptx_has_answer = ww_container.getElementsByClassName('answer').length > 0;
        var b_ptx_has_solution = ww_container.getElementsByClassName('solution').length > 0;
        // get (possibly localized) label text for hints, solutions
        var hint_label_text = 'Hint'
        var solution_label_text = 'Solution'
        if (b_ptx_has_solution) {
            solution_label_text = ww_container.querySelectorAll('.solution-knowl span.type')[0].textContent
        }
        if (b_ptx_has_hint) {
            hint_label_text = ww_container.querySelectorAll('.hint-knowl span.type')[0].textContent
        }
	// record if previous version has show correct answers button
	var b_previous_has_show_correct = ww_container.getElementsByClassName('show-correct').length > 0;
        // void the static/previous version
        ww_container.innerHTML = ""
        // a div for the problem text
        var body_div = document.createElement("div")
        body_div.id = ww_id + "-body"
        body_div.class = "exercise exercise-like"
        body_div.lang = data.lang
        body_div.dir = data.dir
        // dump the problem text, answer blanks, etc. here
        body_div.innerHTML = data.rh_result.text
        // sometimes there are hn headings in the content
        for (const tag_name of ['h6','h5','h4','h3','h2','h1']) {
          var headings = body_div.getElementsByTagName(tag_name);
          for (heading of headings) {
            let new_heading = document.createElement("h6")
            new_heading.innerHTML = heading.innerHTML
            cloneAttributes(new_heading,heading)
            new_heading.className += " " + 'webwork-part';
            heading.parentElement.insertBefore(new_heading,heading)
          }
          for (i = headings.length - 1; i >= 0; i--) {
            headings[i].remove()
          }
        }
        adjustSrcHrefs(body_div,ww_domain)
        translateHintSol(ww_id,body_div,ww_domain,b_ptx_has_hint,b_ptx_has_solution,hint_label_text,solution_label_text)
        // insert our cleaned up problem text
        form.appendChild(body_div)
        /* there are a bunch of hidden input fields that the form uses */
        var answersSubmitted  = document.createElement("input")
        var sourceFilePath    = document.createElement("input")
        var problemSource     = document.createElement("input")
        var problemSeed       = document.createElement("input")
        var problemUUID       = document.createElement("input")
        var psvn              = document.createElement("input")
        var pathToProblemFile = document.createElement("input")
        var courseName        = document.createElement("input")
        var courseID          = document.createElement("input")
        var userID            = document.createElement("input")
        var course_password   = document.createElement("input")
        var displayMode       = document.createElement("input")
        var session_key       = document.createElement("input")
        var outputformat      = document.createElement("input")
        var language          = document.createElement("input")
        var showSummary       = document.createElement("input")
        var forcePortNumber   = document.createElement("input")

        answersSubmitted.type  = 'hidden'
        sourceFilePath.type    = 'hidden'
        problemSource.type     = 'hidden'
        problemSeed.type       = 'hidden'
        problemUUID.type       = 'hidden'
        psvn.type              = 'hidden'
        pathToProblemFile.type = 'hidden'
        courseName.type        = 'hidden'
        courseID.type          = 'hidden'
        userID.type            = 'hidden'
        course_password.type   = 'hidden'
        displayMode.type       = 'hidden'
        session_key.type       = 'hidden'
        outputformat.type      = 'hidden'
        language.type          = 'hidden'
        showSummary.type       = 'hidden'
        forcePortNumber.type   = 'hidden'

        answersSubmitted.name  = 'answersSubmitted'
        sourceFilePath.name    = 'sourceFilePath'
        problemSource.name     = 'problemSource'
        problemSeed.name       = 'problemSeed'
        problemUUID.name       = 'problemUUID'
        psvn.name              = 'psvn'
        pathToProblemFile.name = 'pathToProblemFile'
        courseName.name        = 'courseName'
        courseID.name          = 'courseID'
        userID.name            = 'userID'
        course_password.name   = 'course_password'
        displayMode.name       = 'displayMode'
        session_key.name       = 'session_key'
        outputformat.name      = 'outputformat'
        language.name          = 'language'
        showSummary.name       = 'showSummary'
        forcePortNumber.name   = 'forcePortNumber'

        answersSubmitted.value = 0
        sourceFilePath.value   = ww_sourceFilePath
        problemSource.value    = ww_problemSource
        problemSeed.value      = data.inputs_ref.problemSeed
        problemUUID.value      = data.inputs_ref.problemUUID
        psvn.value             = data.inputs_ref.psvn
        courseName.value       = ww_course_id
        courseID.value         = ww_course_id
        userID.value           = ww_user_id
        course_password.value  = ww_course_password
        displayMode.value      = "MathJax"
        session_key.value      = data.rh_result.session_key
        outputformat.value     = "raw"
        language.value         = data.formLanguage
        showSummary.value      = data.showSummary
        forcePortNumber.value  = data.forcePortNumber

        // add all these inputs to the form
        form.appendChild(answersSubmitted)
        if (ww_sourceFilePath) {
          form.appendChild(sourceFilePath)
        } else if (ww_problemSource) {
          form.appendChild(problemSource)
        }
        form.appendChild(problemSeed)
        form.appendChild(problemUUID)
        form.appendChild(psvn)
        form.appendChild(pathToProblemFile)
        form.appendChild(courseName)
        form.appendChild(courseID)
        form.appendChild(userID)
        form.appendChild(course_password)
        form.appendChild(displayMode)
        form.appendChild(session_key)
        form.appendChild(outputformat)
        form.appendChild(language)
        form.appendChild(showSummary)
        form.appendChild(forcePortNumber)

        // these are the submission button input fields
        var buttons = document.createElement("div")
        buttons.class = 'webwork'
        form.appendChild(buttons)
        // check button
        var check = document.createElement("button")
        check.type = "submit"
        check.textContent = "Check Answer";
        // adjust if more than one answer to check
        let inputCount = body_div.querySelectorAll("input:not([type=hidden])").length;
        let selectCount = body_div.querySelectorAll("select:not([type=hidden])").length;
        let answerCount = inputCount + selectCount;
        if (answerCount > 1) {check.textContent = "Check Answers";};
        check.id = ww_id + '-check'
        buttons.appendChild(check)
        // show correct answers button either if original PTX has answer knowl
        // or if we are reloading and this button was already present
        if (b_ptx_has_answer || b_previous_has_show_correct) {
            // prepare answers object
            var data_answers = data.rh_result.answers
            var answer_ids = Object.keys(data_answers)
            var answers = {}
            answer_ids.forEach(function(id) {
                answers[id] = {
                    "correct_ans": data_answers[id].correct_ans,
                    "correct_ans_latex_string": data_answers[id].correct_ans_latex_string,
                    "correct_choice": data_answers[id].correct_choice
                }
            })
            var correct = document.createElement("button")
            correct.setAttribute('class', "show-correct")
            correct.type = "button"
            correct.textContent = "Show Correct Answer";
            if (answerCount > 1) {correct.textContent = "Show Correct Answers";};
            correct.setAttribute('onclick', "WWshowCorrect('" + ww_id + "'," + JSON.stringify(answers) + ")")
            buttons.appendChild(correct)
        }
        // randomize button
        var randomize = document.createElement("button")
        randomize.type = "button"
        randomize.textContent = "Randomize";
        randomize.setAttribute('onclick', "updateWW('" + ww_id + "', 'randomize')")
        buttons.appendChild(randomize)
        // reset button
        var reset = document.createElement("button")
        reset.type = "button"
        reset.textContent = "Reset";
        reset.setAttribute('onclick', "initWW('" + ww_id + "')")
        buttons.appendChild(reset)
        // insert the form
        ww_container.appendChild(form)
        // run MathJax on our new rendering
        MathJax.typesetPromise([ww_container])
        // place focus
        ww_container.setAttribute('tabindex','-1')
        ww_container.focus()
    });
}


function updateWW(ww_id,task) {
    const ww_container = document.getElementById(ww_id)
    const ww_domain = ww_container.dataset.domain
    let ww_seed = ww_container.dataset.seed
    let ww_problemSource = ww_container.dataset.problemsource
    let ww_sourceFilePath = ww_container.dataset.sourcefilepath
    const ww_course_id = ww_container.dataset.courseid
    const ww_user_id = ww_container.dataset.userid
    const ww_course_password = ww_container.dataset.coursepassword

    let url = new URL(ww_domain + '/webwork2/html2xml')
    if (task == 'randomize') {
        let old_seed = Number(document.getElementById(ww_id + "-form").elements["problemSeed"].value)
        url.searchParams.append("problemSeed", old_seed + 100);
        if (ww_problemSource) {
            url.searchParams.append("problemSource", ww_problemSource);
        } else if (ww_sourceFilePath) {
            url.searchParams.append("sourceFilePath", ww_sourceFilePath);
        }
        url.searchParams.append("answersSubmitted", "0");
        url.searchParams.append("displayMode", "MathJax");
        url.searchParams.append("courseID", ww_course_id);
        url.searchParams.append("userID", ww_user_id);
        url.searchParams.append("course_password", ww_course_password);
        url.searchParams.append("outputformat", "raw");
    }

    if (task == 'check') {
        const formData = new FormData(document.getElementById(ww_id + "-form"));
        const params = new URLSearchParams(formData);
        url = new URL(ww_domain + '/webwork2/html2xml?' + params.toString())
        url.searchParams.append("answersSubmitted", "1");
        url.searchParams.append('WWsubmit',"1")
    }

    // get the json and do stuff with what we get
    $.getJSON(url.toString(), function(data) {
        data.ww_id = ww_id
        // get the form
        var form = document.getElementById(ww_id + "-form")
        // Runestone trigger
        // TODO: chondition on platform=Runestone
        if (task == 'check') {
            $("body").trigger('runestone_ww_check', data)
        }
        // get the body div
        var body_div = document.getElementById(ww_id + "-body")
        // determine if previous version shows hints, solutions, answers
        var b_ptx_has_hint = ww_container.getElementsByClassName('hint').length > 0;
        var b_ptx_has_answer = ww_container.getElementsByClassName('answer').length > 0;
        var b_ptx_has_solution = ww_container.getElementsByClassName('solution').length > 0;
        // get (possibly localized) label text for hints, solutions
        var hint_label_text = 'Hint'
        var solution_label_text = 'Solution'
        if (b_ptx_has_solution) {
            solution_label_text = ww_container.querySelectorAll('.solution-knowl span.type')[0].textContent
        }
        if (b_ptx_has_hint) {
            hint_label_text = ww_container.querySelectorAll('.hint-knowl span.type')[0].textContent
        }
        // dump the problem text, answer blanks, etc. here
        body_div.innerHTML = data.rh_result.text
        adjustSrcHrefs(body_div,ww_domain)
        translateHintSol(ww_id,body_div,ww_domain,b_ptx_has_hint,b_ptx_has_solution,hint_label_text,solution_label_text)
        // there are a bunch of hidden input fields that the form uses
        var answersSubmitted  = document.querySelector("#" + ww_id + "-form input[name='answersSubmitted']")
        var problemSeed       = document.querySelector("#" + ww_id + "-form input[name='problemSeed']")
        var problemUUID       = document.querySelector("#" + ww_id + "-form input[name='problemUUID']")
        var psvn              = document.querySelector("#" + ww_id + "-form input[name='psvn']")
        var session_key       = document.querySelector("#" + ww_id + "-form input[name='session_key']")
        var language          = document.querySelector("#" + ww_id + "-form input[name='language']")
        var showSummary       = document.querySelector("#" + ww_id + "-form input[name='showSummary']")
        var forcePortNumber   = document.querySelector("#" + ww_id + "-form input[name='forcePortNumber']")

        answersSubmitted.value = 1
        problemSeed.value      = data.inputs_ref.problemSeed
        problemUUID.value      = data.inputs_ref.problemUUID
        psvn.value             = data.inputs_ref.psvn
        session_key.value      = data.rh_result.session_key
        language.value         = data.formLanguage
        showSummary.value      = data.showSummary
        forcePortNumber.value  = data.forcePortNumber

        // prepare answers object
        var data_answers = data.rh_result.answers
        var answer_ids = Object.keys(data_answers)
        var answers = {}
        answer_ids.forEach(function(id) {
            answers[id] = {
                "correct_ans": data_answers[id].correct_ans,
                "correct_ans_latex_string": data_answers[id].correct_ans_latex_string,
                "correct_choice": data_answers[id].correct_choice
            }
        })

        // show correct answers button
        // if present, needs to be updated in case of randomizing
        if (b_ptx_has_answer) {
            var correct = document.querySelector("#" + ww_id + "-form div button.show-correct")
            correct.setAttribute('onclick', "WWshowCorrect('" + ww_id + "'," + JSON.stringify(answers) + ")")
        }
        // insert results near/around input fields
        if (task == 'check') {
            let inputs = body_div.querySelectorAll("input:not([type=hidden])");
            for (const input of inputs) {
              var name = input.name
              if (input.type == 'text' && answers[name]) {
                  let label = document.createElement('label')
                  label.id = ww_id + '-' + name + '-label'
                  input.parentNode.insertBefore(label, input);
                  label.appendChild(input);
                  let status_span = document.createElement('span');
                  status_span.setAttribute('class','status');
                  label.appendChild(status_span);
                  let status_text = ''
                  if (data.rh_result.answers[name].score == 1) {
                    status_text = 'Correct!'
                    label.setAttribute('class','webwork correct')
                  } else if (data.rh_result.answers[name].score > 0 && data.rh_result.answers[name].score < 1) {
                    status_text = Math.round(data.rh_result.answers[name].score*100) + "% correct."
                    label.setAttribute('class','webwork partly-correct')
                  } else if (data.rh_result.answers[name].student_ans == '') {
                    // do nothing if the submitted answer is blank and that has not already been scored as correct
                  } else if (data.rh_result.answers[name].score == 0) {
                    status_text = 'incorrect'
                    label.setAttribute('class','webwork incorrect')
                  }
                  let status_span_text = document.createTextNode(status_text);
                  status_span.appendChild(status_span_text);
                  let feedback_span = document.createElement('span');
                  feedback_span.setAttribute('class','feedback');
                  let feedback_text = data.rh_result.answers[name].ans_message
                  if (feedback_text) {
                    let feedback_span_text = document.createTextNode(feedback_text);
                    label.appendChild(feedback_span);
                    feedback_span.style.maxWidth = input.offsetWidth + "px";
                    feedback_span.appendChild(feedback_span_text);
                  } 
              }

              if (input.type == 'radio' && answers[name]) {
                if (input.value == data.rh_result.answers[name].student_value) {
                  let pre_span = document.createElement('span');
                  if (data.rh_result.answers[name].student_value == data.rh_result.answers[name].correct_choice) {
                    var correct_text = 'Correct!'
                    input.parentElement.setAttribute('class','correct')
                    pre_span.style.backgroundColor = '#8F8'
                  } else {
                    var correct_text = 'Incorrect.'
                    input.parentElement.setAttribute('class','incorrect')
                    pre_span.style.color = '#bf5454'
                  }
                  let pre_text = document.createTextNode(correct_text);
                  pre_span.appendChild(pre_text);
                  input.parentElement.insertBefore(pre_span,input)
                }
              }
            }

            let selects = body_div.querySelectorAll("select:not([type=hidden])");
            for (const select of selects) {
              var name = select.name
              let label = document.createElement('label')
              label.id = ww_id + '-' + name + '-label'
              select.parentNode.insertBefore(label, select);
              let pre_span = document.createElement('span');
              label.appendChild(pre_span);
              let correct_text = ''
              if (data.rh_result.answers[name].score == 1) {
                correct_text = 'Correct!'
                label.setAttribute('class','correct')
                pre_span.style.backgroundColor = '#8F8'
              } else if (data.rh_result.answers[name].score == 0) {
                correct_text = 'Incorrect.'
                label.setAttribute('class','incorrect')
                pre_span.style.color = '#bf5454'
              }
              let pre_text = document.createTextNode(correct_text);
              pre_span.appendChild(pre_text);
              label.appendChild(select);
            }
        }
        // run MathJax on our new rendering
        MathJax.typesetPromise([ww_container])
    });
}

function WWshowCorrect(ww_id, answers) {
    var body = document.getElementById(ww_id + '-body')
    $("body").trigger("runestone_show_correct", {
        "ww_id": ww_id,
        "answers": answers,
    });

    let inputs = body.querySelectorAll("input:not([type=hidden])");
    for (const input of inputs) {
      var name = input.name
      var span_id = ww_id + '-' + name

      if (input.type == 'text' && answers[name] && !(document.getElementById(span_id))) {
          label = document.getElementById(ww_id + '-' + name + '-label')
          if (label) {
            label.parentElement.insertBefore(input,label)
            label.remove()
          }
          input.type = "hidden"
          // we need to convert things like &lt; in answers to <
          correct_ans_text = document.createElement('div')
          correct_ans_text.innerHTML = answers[name].correct_ans
          input.value = correct_ans_text.textContent
          var show_span = document.createElement('span')
          show_span.id = span_id
          if (typeof answers[name].correct_ans_latex_string !== 'undefined') {
            var show = document.createTextNode('\\(' + answers[name].correct_ans_latex_string + '\\)')
          } else {
            var show = document.createTextNode(answers[name].correct_ans)
          }
          show_span.appendChild(show)
          input.parentElement.insertBefore(show_span,input)
      }

      if (input.type == 'radio' && answers[name]) {
          correct_value = answers[name].correct_choice
          if (input.value == correct_value) {
            input.checked = true
          }
      }
    }

    let selects = body.querySelectorAll("select:not([type=hidden])");
    for (const select of selects) {
      var name = select.name
      var span_id = ww_id + '-' + name
      if (answers[name] && !(document.getElementById(span_id))) {
          select.style.display = "none"
          select.value = answers[name].correct_ans
          var show_span = document.createElement('span')
          show_span.id = span_id
          if (typeof answers[name].correct_ans_latex_string !== 'undefined') {
            var show = document.createTextNode('\\(' + answers[name].correct_ans_latex_string + '\\)')
          } else {
            var show = document.createTextNode(answers[name].correct_ans)
          }
          show_span.appendChild(show)
          select.parentElement.insertBefore(show_span,select)
      }
    }

    MathJax.typesetPromise([body])
}

function adjustSrcHrefs(container,ww_domain) {
  container.querySelectorAll('[href]').forEach((node) => {
    const href = node.attributes.href.value;
    if (href !== '#' && !href.match(/^[a-z]+:\/\//i)) node.href = ww_domain + '/' + href;
  });
  container.querySelectorAll('[src]').forEach((node) => {
    node.src = ww_domain + '/' + node.attributes.src.value;
  });
}

function translateHintSol(ww_id,body_div,ww_domain,b_ptx_has_hint,b_ptx_has_solution,hint_label_text,solution_label_text) {
  // the problem text may come with "hint"s and "solution"s
  // each one is an "a" with content "Hint" or "Solution", and an attribute with base64-encoded HTML content
  // the WeBWorK knowl js would normally handle this, but we want PreTeXt knowl js to handle it
  // so we replace the "a" with the content that should be there for PTX knowl js
  // also if hint/sol were missing from the static version, we want these removed here
  var hintxpath = "//a[b='Hint:']";
  var solutionxpath = "//a[b='Solution:']";
  var hintnodes = document.evaluate(hintxpath, body_div, null, XPathResult.UNORDERED_NODE_SNAPSHOT_TYPE, null);
  var b_ww_has_hint = hintnodes.snapshotLength > 0;
  var solutionnodes = document.evaluate(solutionxpath, body_div, null, XPathResult.UNORDERED_NODE_SNAPSHOT_TYPE, null);
  var b_ww_has_solution = solutionnodes.snapshotLength > 0;
  if ((b_ww_has_hint && b_ptx_has_hint) || (b_ww_has_solution && b_ptx_has_solution)) {
      var solutionlikewrapper = document.createElement('div');
      solutionlikewrapper.setAttribute('class', 'webwork solutions');
      if (b_ww_has_hint && b_ptx_has_hint) {hintnodes.snapshotItem(0).parentNode.insertBefore(solutionlikewrapper, hintnodes.snapshotItem(0));}
      else if (b_ww_has_solution && b_ptx_has_solution) {solutionnodes.snapshotItem(0).parentNode.insertBefore(solutionlikewrapper, solutionnodes.snapshotItem(0));}
  }
  if (hintnodes) {
      for(var i = hintnodes.snapshotLength; i >= 0; i--) {
        var hintanchor = hintnodes.snapshotItem(i);
        if (b_ptx_has_hint && hintanchor) {
          var hintbase64 = hintanchor.attributes.value.value;
          var hint = atob(hintbase64);
          hintanchor.setAttribute('class', 'id-ref hint-knowl');
          hintanchor.setAttribute('data-knowl', '');
          hintanchor.setAttribute('data-refid', 'hk-hint-' + ww_id);
          hintlabel = document.createElement('span');
          hintlabel.setAttribute('class', 'type');
          hintanchor.innerHTML = "";
          hintanchor.appendChild(hintlabel);
          hintlabel.innerHTML = hint_label_text;
          var hkhintdiv = document.createElement('div');
          hkhintdiv.setAttribute('class', 'hidden-content tex2jax_ignore');
          hkhintdiv.setAttribute('id', 'hk-hint-' + ww_id);
          var hintdivdiv = document.createElement('div');
          hintdivdiv.setAttribute('class', 'hint solution-like');
          hkhintdiv.appendChild(hintdivdiv);
          hintdivdiv.innerHTML = hint;
          adjustSrcHrefs(hintdivdiv,ww_domain)
          solutionlikewrapper.appendChild(hintanchor);
          hintanchor.parentNode.insertBefore(hkhintdiv, hintanchor.nextSibling);
        } else if (hintanchor) {
          hintanchor.remove()
        }
      }
  }
  if (solutionnodes) {
      for(var i = solutionnodes.snapshotLength; i >= 0; i--) {
        var solutionanchor = solutionnodes.snapshotItem(i);
        if (b_ptx_has_solution && solutionanchor) {
          var solutionbase64 = solutionanchor.attributes.value.value;
          var solution = atob(solutionbase64);
          solutionanchor.setAttribute('class', 'id-ref solution-knowl');
          solutionanchor.setAttribute('data-knowl', '');
          solutionanchor.setAttribute('data-refid', 'hk-solution-' + ww_id);
          solutionlabel = document.createElement('span');
          solutionlabel.setAttribute('class', 'type');
          solutionanchor.innerHTML = "";
          solutionanchor.appendChild(solutionlabel);
          solutionlabel.innerHTML = solution_label_text;
          var hksolutiondiv = document.createElement('div');
          hksolutiondiv.setAttribute('class', 'hidden-content tex2jax_ignore');
          hksolutiondiv.setAttribute('id', 'hk-solution-' + ww_id);
          var solutiondivdiv = document.createElement('div');
          solutiondivdiv.setAttribute('class', 'solution solution-like');
          hksolutiondiv.appendChild(solutiondivdiv);
          solutiondivdiv.innerHTML = solution;
          adjustSrcHrefs(solutiondivdiv,ww_domain)
          solutionlikewrapper.appendChild(solutionanchor);
          solutionanchor.parentNode.insertBefore(hksolutiondiv, solutionanchor.nextSibling);
        } else if (solutionanchor) {
          solutionanchor.remove()
        }
      }
  }
}

function cloneAttributes(target, source) {
  [...source.attributes].forEach( attr => { target.setAttribute(attr.nodeName ,attr.nodeValue) })
}
