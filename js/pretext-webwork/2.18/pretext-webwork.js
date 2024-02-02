//Critical:
// TODO: Think about what should be done for an essay question.

//Accessibility:

//Enhancement:
// TODO: In a scaffold problem, adjust the green bar for when one part is correct.
// TODO: Have randomize check that new seed is actually producing new HTML.
// TODO: Don't offer randomize or button unless we know a new version can be produced after trying a few seeds.
// TODO: In a staged problem, Make Interactive button is adjacent to solution knowls; move it.
// TODO: MathQuill
// TODO: Image pop up.
// TODO: Deal with singleResult MultiAnswer problems.

//Styling:
// TODO: Review all styling in all scenarios (staged/not, correct/partly-correct/incorrect/blank, single/multiple)
// TODO: Sean: I think I'd like to see a slightly larger font size on the buttons

function handleWW(ww_id, action) {
	const ww_container = document.getElementById(ww_id);
	const ww_domain = ww_container.dataset.domain;
	const ww_problemSource = ww_container.dataset.problemsource;
	const ww_sourceFilePath = ww_container.dataset.sourcefilepath;
	const ww_course_id = ww_container.dataset.courseid;
	const ww_user_id = ww_container.dataset.userid;
	const ww_course_password = ww_container.dataset.coursepassword;
	const localize_correct = ww_container.dataset.localizeCorrect || "Correct";
	const localize_incorrect = ww_container.dataset.localizeIncorrect || "Incorrect";
	const localize_blank = ww_container.dataset.localizeBlank || "Blank";
	const localize_submit = ww_container.dataset.localizeSubmit || "Submit";
	const localize_check_responses = ww_container.dataset.localizeCheckResponses || "Check Responses";
	const localize_reveal = ww_container.dataset.localizeReveal || "Reveal";
	const localize_randomize = ww_container.dataset.localizeRandomize || "Randomize";
	const localize_reset = ww_container.dataset.localizeReset || "Reset";
	const runestone_logged_in = (typeof eBookConfig !== 'undefined' && eBookConfig.username !== '');
	// will be null on pages generated prior to late December 2022
	const activate_button = document.getElementById(ww_id + '-button')

	// Set the current seed
	if (!action) {
		ww_container.dataset.current_seed = ww_container.dataset.seed;
		if (runestone_logged_in) {
			ww_container.dataset.current_seed = webworkSeedHash(eBookConfig.username + ww_container.dataset.current_seed);
		}
	}
	else if (action == 'randomize') ww_container.dataset.current_seed = Number(ww_container.dataset.current_seed) + 100;

	let loader = document.createElement('div');
	loader.style.position = 'absolute';
	loader.style.left = 0;
	loader.style.top = 0;
	loader.style.backgroundColor = 'rgba(0.2, 0.2, 0.2, 0.4)';
	loader.style.color = 'white';
	loader.style.width = '100%';
	loader.style.height = '100%';
	loader.style.display = 'flex';
	loader.style.alignItems = 'center';
	loader.style.justifyContent = 'center';
	loader.tabIndex = -1;
	const loaderText = document.createElement('span');
	loaderText.textContent = 'Loading';
	loaderText.style.fontSize = '2rem';
	loader.appendChild(loaderText);
	ww_container.appendChild(loader);
	loader.focus();

	if (!action) {
		// Determine if static version shows hints, solutions, or answers and save that information in the container dataset for later runs.
		ww_container.dataset.hasHint = ww_container.getElementsByClassName('hint').length > 0;
		ww_container.dataset.hasSolution = ww_container.getElementsByClassName('solution').length > 0;
		ww_container.dataset.hasAnswer = ww_container.getElementsByClassName('answer').length > 0;
		// Get (possibly localized) label text for hints and solutions.
		ww_container.dataset.hintLabelText = ww_container.dataset.hasHint == 'true'
			? ww_container.querySelectorAll('.hint-knowl span.type, details.hint span.type')[0].textContent : 'Hint';
		ww_container.dataset.solutionLabelText = ww_container.dataset.hasSolution == 'true'
			? ww_container.querySelectorAll('.solution-knowl span.type, details.solution span.type')[0].textContent : 'Solution';

		ww_container.tabIndex = -1;
	}

	let url;

	if (action == 'check') {
		const iframe = ww_container.querySelector('.problem-iframe');
		const formData = new FormData(iframe.contentDocument.getElementById(ww_id + "-form"));
		const params = new URLSearchParams(formData);
		url = new URL(ww_domain + '/webwork2/html2xml?' + params.toString())
		url.searchParams.append("answersSubmitted", '1');
		url.searchParams.append('WWsubmit', "1");
	} else {
		url = new URL(ww_domain + '/webwork2/html2xml');
		url.searchParams.append("problemSeed", ww_container.dataset.current_seed);
		if (ww_problemSource) url.searchParams.append("problemSource", ww_problemSource);
		else if (ww_sourceFilePath) url.searchParams.append("sourceFilePath", ww_sourceFilePath);
		url.searchParams.append("answersSubmitted", '0');
		url.searchParams.append("displayMode", "MathJax");
		url.searchParams.append("courseID", ww_course_id);
		url.searchParams.append("userID", ww_user_id);
		url.searchParams.append("course_password", ww_course_password);
		url.searchParams.append("outputformat", "raw");
		// note ww_container.dataset.hasSolution is a string, possibly 'false' which is true
		url.searchParams.append("showSolutions", ww_container.dataset.hasSolution == 'true' ? '1' : '0');
		url.searchParams.append("showHints", ww_container.dataset.hasHint == 'true' ? '1' : '0');
		url.searchParams.append("problemUUID",ww_id);
	}

	// get the json and do stuff with what we get
	$.getJSON(url.toString(), (data) => {
		// Create the form that will contain the text and input fields of the interactive problem.
		const form = document.createElement("form");
		form.id = ww_id + "-form";

		// Create a div for the problem text.
		const body_div = document.createElement("div");
		body_div.id = ww_id + "-body";
		body_div.classList.add("exercise", "exercise-like");
		body_div.lang = data.lang;
		body_div.dir = data.dir;

		// Dump the problem text, answer blanks, etc.
		body_div.innerHTML = data.rh_result.text;

		// Replace all hn headings with h6 headings.
		for (const tag_name of ['h6', 'h5', 'h4', 'h3', 'h2', 'h1']) {
			const headings = body_div.getElementsByTagName(tag_name);
			for (heading of headings) {
				const new_heading = document.createElement("h6");
				new_heading.innerHTML = heading.innerHTML;
				cloneAttributes(new_heading, heading);
				new_heading.classList.add('webwork-part');
				heading.replaceWith(new_heading);
			}
		}

		adjustSrcHrefs(body_div, ww_domain);

		translateHintSol(ww_id, body_div, ww_domain,
			ww_container.dataset.hasHint == 'true', ww_container.dataset.hasSolution == 'true',
			ww_container.dataset.hintLabelText, ww_container.dataset.solutionLabelText)

		// insert previous answers
		if (runestone_logged_in) {
			const answersObject = (wwList[ww_id.replace(/-ww-rs$/,'')].answers ? wwList[ww_id.replace(/-ww-rs$/,'')].answers : {'answers' : [], 'mqAnswers' : []});
			const mqAnswers = answersObject.mqAnswers;
			for (const mqAnswer in mqAnswers) {
				const mqInput = body_div.querySelector('input[id=' + mqAnswer + ']');
				if (mqInput && mqInput.value == '') {
					mqInput.setAttribute('value', mqAnswers[mqAnswer]);
				}
			}
			const answers = answersObject.answers;
			for (const answer in answers) {
				const input = body_div.querySelector('input[id=' + answer + ']');
				if (input && input.value == '') {
					input.setAttribute('value', answers[answer]);
				}
				if (input && input.type.toUpperCase() == 'RADIO') {
					const buttons = body_div.querySelectorAll('input[name=' + answer + ']');
					for (const button of buttons) {
						if (button.value == answers[answer]) {
							button.setAttribute('checked', 'checked');
						}
					}
				}
				if (input && input.type.toUpperCase() == 'CHECKBOX') {
					const checkboxes = body_div.querySelectorAll('input[name=' + answer + ']');
					for (const checkbox of checkboxes) {
						// This is not a bulletproof approach if the problem used input values that are weird
						// For example, with commas in them
						// However, we are stuck with WW providing answers[answer] as a string like `[value0, value1]`
						// and note that it is not `["value0", "value1"]`, so we cannot cleanly parse it into an array
						let checkbox_regex = new RegExp('(\\[|, )' + checkbox.value + '(, |\\])');
						if (answers[answer].match(checkbox_regex)) {
							checkbox.setAttribute('checked', 'checked');
						}
					}
				}
				var select = body_div.querySelector('select[id=' + answer + ']');
				if (select && answers[answer]) {
					// answers[answer] may be wrapped in \text{...} that we want to remove, since value does not have this.
					let this_answer = answers[answer];
					if (/^\\text\{.*\}$/.test(this_answer)) {this_answer = this_answer.match(/^\\text\{(.*)\}$/)[1]};
					let quote_escaped_answer = this_answer.replace(/"/g, '\\"');
					const option = body_div.querySelector(`select[id="${answer}"] option[value="${quote_escaped_answer}"]`);
					if (option) {option.setAttribute('selected', 'selected')};
				}
			}
		}

		// insert our cleaned up problem text
		form.appendChild(body_div);

		// Set up hidden input fields that the form uses
		const wwInputs = {
			problemSeed:      data.inputs_ref.problemSeed,
			problemUUID:      data.inputs_ref.problemUUID,
			psvn:             data.inputs_ref.psvn,
			courseName:       ww_course_id,
			courseID:         ww_course_id,
			userID:           ww_user_id,
			course_password:  ww_course_password,
			displayMode:      "MathJax",
			session_key:      data.rh_result.session_key,
			outputformat:     "raw",
			language:         data.formLanguage,
			showSummary:      data.showSummary,
			// note ww_container.dataset.hasSolution is a string, possibly 'false' which is true
			showSolutions:    ww_container.dataset.hasSolution == 'true' ? '1' : '0',
			showHints:        ww_container.dataset.hasHint == 'true' ? '1' : '0',
			forcePortNumber:  data.forcePortNumber
		};

		if (ww_sourceFilePath) wwInputs.sourceFilePath = ww_sourceFilePath;
		else if (ww_problemSource) wwInputs.problemSource = ww_problemSource;

		for (const wwInputName of Object.keys(wwInputs)) {
			const input = document.createElement('input');
			input.type = 'hidden';
			input.name = wwInputName;
			input.value = wwInputs[wwInputName];
			form.appendChild(input);
		}

		// Prepare answers object
		const answers = {};
		// id the answers even if we won't populate them
		Object.keys(data.rh_result.answers).forEach(function(id) {
			answers[id] = {};
		}, data.rh_result.answers);
		if (ww_container.dataset.hasAnswer == 'true') {
			// Update answer data
			Object.keys(data.rh_result.answers).forEach(function(id) {
				answers[id] = {
					correct_ans: this[id].correct_ans,
					correct_ans_latex_string: this[id].correct_ans_latex_string,
					correct_choice: this[id].correct_choice,
					correct_choices: this[id].correct_choices,
				};
			}, data.rh_result.answers);
		}

		let buttonContainer = ww_container.querySelector('.problem-buttons.webwork');
		// Create the submission buttons if they have not yet been created.
		if (!buttonContainer) {
			// Hide the original div that contains the old make active button.
			ww_container.querySelector('.problem-buttons').classList.add('hidden-content');
			// And the newer activate button if it is there
			if (activate_button != null) {activate_button.classList.add('hidden-content');};

			// Create a new div for the webwork buttons.
			buttonContainer = document.createElement('div');
			buttonContainer.classList.add('problem-buttons', 'webwork');
			if (activate_button != null) {
				// Make sure the button container follows the activate button in the DOM
				activate_button.after(buttonContainer);
			} else {
				ww_container.prepend(buttonContainer);
			}

			// Check button
			const check = document.createElement("button");
			check.type = "button";
			check.id = ww_id + '-check';
			check.style.marginRight = "0.25rem";
			check.classList.add('webwork-button');

			// Adjust if more than one answer to check
			const answerCount = body_div.querySelectorAll("input:not([type=hidden])").length +
				body_div.querySelectorAll("select:not([type=hidden])").length;

			check.textContent = runestone_logged_in ? localize_submit : localize_check_responses;
			check.addEventListener('click', () => handleWW(ww_id, "check"));

			buttonContainer.appendChild(check);

			// Show correct answers button if original PTX has answer knowl.
			if (ww_container.dataset.hasAnswer == 'true') {
				const correct = document.createElement("button");
				correct.classList.add("show-correct", 'webwork-button');
				correct.type = "button";
				correct.style.marginRight = "0.25rem";
				correct.textContent = localize_reveal;
				correct.addEventListener('click', () => WWshowCorrect(ww_id, answers));
				buttonContainer.appendChild(correct);
			}

			// randomize button
			const randomize = document.createElement("button")
			randomize.type = "button";
			randomize.classList.add('webwork-button');
			randomize.style.marginRight = "0.25rem";
			randomize.textContent = localize_randomize;
			randomize.addEventListener('click', () => handleWW(ww_id, 'randomize'));
			buttonContainer.appendChild(randomize)

			// reset button
			const reset = document.createElement("button")
			reset.type = "button"
			reset.classList.add('webwork-button');
			reset.textContent = localize_reset;
			reset.addEventListener('click', () => resetWW(ww_id));
			buttonContainer.appendChild(reset)
		} else {
			// Update the click handler for the show correct button.
			if (ww_container.dataset.hasAnswer == 'true') {
				const correct = buttonContainer.querySelector('.show-correct');
				const correctNew = correct.cloneNode(true);
				correctNew.addEventListener('click', () => WWshowCorrect(ww_id, answers));
				correct.replaceWith(correctNew);
			}
		}

		if (action == 'check') {
			// Runestone trigger
			// TODO: condition on platform=Runestone
			$("body").trigger('runestone_ww_check', data)

			const inputs = body_div.querySelectorAll("input:not([type=hidden])");
			for (const input of inputs) {
				const name = input.name;
				if (input.type == 'text' && answers[name]) {
					const score = data.rh_result.answers[name].score;
					let headline = '';
					let correctClass = '';
					if (score >= 1) {
						headline = localize_correct + '!';
						correctClass = 'correct';
					} else if (score > 0 && score < 1) {
						headline = `${Math.round(score * 100)}% ${localize_correct}.`;
						correctClass = 'partly-correct';
					} else if (data.rh_result.answers[name].student_ans == '') {
						headline = localize_blank + '.';
						correctClass = 'blank';
					} else if (score <= 0) {
						headline = localize_incorrect + '.';
						correctClass = 'incorrect';
					}
					let title = `<span class="${correctClass}">${headline}</span>`;
					let message = (data.rh_result.answers[name].ans_message ? data.rh_result.answers[name].ans_message : '');
					input.classList.add(correctClass);
					// make a span that contains feedback
					feedbackSpan = document.createElement('span');
					feedbackSpan.id = `${ww_id}-${name}-feedback`;
					feedbackHeadline = document.createElement('span');
					feedbackHeadline.id = `${ww_id}-${name}-headline`;
					feedbackHeadline.textContent = headline;
					feedbackSpan.appendChild(feedbackHeadline);
					feedbackMessage = document.createElement('span');
					feedbackMessage.id = `${ww_id}-${name}-message`;
					feedbackMessage.textContent = message;
					feedbackSpan.appendChild(feedbackMessage);
					// make a non breaking span to surround input, sr span, and feedback button
					let nbSpan = document.createElement('span');
					nbSpan.classList.add("nobreak");
					input.parentNode.insertBefore(nbSpan, input);
					nbSpan.appendChild(input);
					// put a visibly hidden (screen-reader only) span with feedback
					let srSpan = document.createElement('span');
					srSpan.classList.add("visually-hidden");
					srSpan.appendChild(feedbackSpan);
					nbSpan.appendChild(srSpan);
					// give the feedback to sr users immediately
					input.setAttribute('aria-describedby',`${ww_id}-${name}-feedback`);
					// make the feedback button
					srSpan.after(createFeedbackButton(`${ww_id}-${name}`, title, message));
	
				}

				if (input.type.toUpperCase() == 'RADIO' && answers[name]) {
					const score = data.rh_result.answers[name].score;
					const student_ans = data.rh_result.answers[name].student_value || data.rh_result.answers[name].student_ans;
					const correct_ans = data.rh_result.answers[name].correct_choice || data.rh_result.answers[name].correct_ans;
					if (input.value == student_ans) {
						if (score == 1) {
							input.parentNode.classList.add('correct');
						} else {
							input.parentNode.classList.add('incorrect');
						}
						const feedbackButton = createFeedbackButton(`${ww_id}-${name}`,
							(student_ans == correct_ans)
							? `<span class="correct">${localize_correct}</span>` : `<span class="incorrect">${localize_incorrect}.</span>`)
						feedbackButton.style.marginRight = '0.25rem';
						input.after(feedbackButton);
					}
				}

				if (input.type.toUpperCase() == 'CHECKBOX' && answers[name]) {
					const score = data.rh_result.answers[name].score;
					const student_ans = data.rh_result.answers[name].student_ans;
					const correct_ans = data.rh_result.answers[name].correct_ans;
					if (input.value == data.rh_result.answers[name].firstElement) {
						const checkbox_div = input.parentNode.parentNode;
						if (score == 1) {
							checkbox_div.classList.add('correct');
						} else {
							checkbox_div.classList.add('incorrect');
						}
						const feedbackButton = createFeedbackButton(`${ww_id}-${name}`,
							(student_ans == correct_ans)
							? `<span class="correct">${localize_correct}</span>` : `<span class="incorrect">${localize_incorrect}.</span>`)
						checkbox_div.insertBefore(feedbackButton, checkbox_div.firstChild);
					}
				}
			}

			const hiddenInputs = body_div.querySelectorAll("input[type=hidden]");
			for (const input of hiddenInputs) {
				const name = input.name;
				if (!input.nextElementSibling) continue;
				const graphtoolContainer = input.nextElementSibling.nextElementSibling;
				if (graphtoolContainer && answers[name] && graphtoolContainer.classList.contains('graphtool-container')) {
					graphtoolContainer.style.position = 'relative';
					const score = data.rh_result.answers[name].score;
					let title = '';
					if (score == 1) {
						title = `<span class="correct">${localize_correct}</span>`;
					} else if (score > 0 && score < 1) {
						title = `<span class="partly-correct">${Math.round(score * 100)}% ${localize_correct}.</span>`;
					} else if (data.rh_result.answers[name].student_ans == '') {
						// do nothing if the submitted answer is blank and the problem has not already been scored as correct
						continue;
					} else if (score == 0) {
						title = `<span class="incorrect">${localize_incorrect}.</span>`;
					}

					const feedbackButton = createFeedbackButton(`${ww_id}-${name}`, title, data.rh_result.answers[name].ans_message);
					feedbackButton.style.position = 'absolute';
					feedbackButton.style.left = '100%';
					feedbackButton.style.top = 0;
					feedbackButton.style.marginLeft = '0.5rem';
					feedbackButton.dataset.bsContainer = 'body';
					graphtoolContainer.appendChild(feedbackButton);
					if (score == 1) {
						graphtoolContainer.classList.add('correct');
					} else {
						graphtoolContainer.classList.add('incorrect');
					}
					
				}
			}

			const selects = body_div.querySelectorAll("select:not([type=hidden])");
			for (const select of selects) {
				const name = select.name;
				const score = data.rh_result.answers[name].score;
				let title = '';
				if (score == 1) {
					headline = localize_correct + '!';
					correctClass = 'correct';
				} else {
					headline = localize_incorrect + '.';
					correctClass = 'incorrect';
				}
				select.classList.add(correctClass);
				title = `<span class="${correctClass}">${headline}</span>`;
				// make a span that contains feedback
				feedbackSpan = document.createElement('span');
				feedbackSpan.id = `${ww_id}-${name}-feedback`;
				feedbackHeadline = document.createElement('span');
				feedbackHeadline.id = `${ww_id}-${name}-headline`;
				feedbackHeadline.textContent = headline;
				feedbackSpan.appendChild(feedbackHeadline);
				// make a non breaking span to surround select, sr span, and feedback button
				let nbSpan = document.createElement('span');
				nbSpan.classList.add("nobreak");
				select.parentNode.insertBefore(nbSpan, select);
				nbSpan.appendChild(select);
				// put a span around select since select does not support ::after pseudo elements
				let psSpan = document.createElement('span');
				psSpan.classList.add("select-wrapper", correctClass);
				select.parentNode.insertBefore(psSpan, select);
				psSpan.appendChild(select);
				// put a visibly hidden (screen-reader only) span with feedback
				let srSpan = document.createElement('span');
				srSpan.classList.add("visually-hidden");
				srSpan.appendChild(feedbackSpan);
				nbSpan.appendChild(srSpan);
				// give the feedback to sr users immediately
				select.setAttribute('aria-describedby',`${ww_id}-${name}-feedback`);
				// make the feedback button
				srSpan.after(createFeedbackButton(`${ww_id}-${name}`, title));
			}
		}

		let iframeContents = '<!DOCTYPE html><head>' +
			'<script src="' + ww_domain + '/webwork2_files/node_modules/jquery/dist/jquery.min.js"></script>' +
			`<script>window.MathJax = {
			  tex: {
				inlineMath: [['\\\\(','\\\\)']],
				tags: "none",
				useLabelIds: true,
				tagSide: "right",
				tagIndent: ".8em",
				packages: {'[+]': ['base', 'extpfeil', 'ams', 'amscd', 'newcommand', 'knowl']}
			  },
			  options: {
				ignoreHtmlClass: "tex2jax_ignore",
				processHtmlClass: "has_am",
				renderActions: {
					findScript: [10, function (doc) {
						document.querySelectorAll('script[type^="math/tex"]').forEach(function(node) {
							const display = !!node.type.match(/; *mode=display/);
							const math = new doc.options.MathItem(node.textContent, doc.inputJax[0], display);
							const text = document.createTextNode('');
							node.parentNode.replaceChild(text, node);
							math.start = {node: text, delim: '', n: 0};
							math.end = {node: text, delim: '', n: 0};
							doc.math.push(math);
						});
					}, '']
				},
			  },
			  chtml: {
				scale: 0.88,
				mtextInheritFont: true
			  },
			  loader: {
				load: ['input/asciimath', '[tex]/extpfeil', '[tex]/amscd', '[tex]/newcommand', '[pretext]/mathjaxknowl3.js'],
				paths: {pretext: "https://pretextbook.org/js/lib"},
			  },
			};
			</script>` +
			'<script src="' + ww_domain + '/webwork2_files/node_modules/mathjax/es5/tex-chtml.js" id="MathJax-script" defer></script>' +
			'<script src="https://pretextbook.org/js/lib/knowl.js" defer></script>' +
			'<link rel="stylesheet" href="' + ww_domain + '/webwork2_files/node_modules/bootstrap/dist/css/bootstrap.min.css"/>' +
			'<script src="' + ww_domain + '/webwork2_files/node_modules/bootstrap/dist/js/bootstrap.bundle.min.js" defer></script>';

		// Determine javascript and css dependencies
		const extra_css_files = [];
		const extra_js_files = [];
		//if (data.rh_result.flags.extra_js_files) {
		//    for (const jsFile of data.rh_result.flags.extra_js_files) {
		//        if (jsFile.file == "js/apps/GraphTool/graphtool.min.js" || jsFile.file == "js/apps/Scaffold/scaffold.js") {
		//            extra_css_files.push({ file: 'js/vendor/bootstrap/css/bootstrap.css', external: '0' });
		//            extra_css_files.push({ file: 'themes/math4/math4.css', external: '0' });
		//            extra_js_files.push({ file: 'js/vendor/bootstrap/js/bootstrap.js', external: '0' });
		//        }
		//    }
		//}

		if (data.extra_css_files) data.extra_css_files.unshift(...extra_css_files);
		else data.extra_css_files = extra_css_files;
		for (const cssFile of data.extra_css_files) {
			if (/knowl/.test(cssFile.file)) continue;
			iframeContents += '<link rel="stylesheet" href="' + (cssFile.external !== '1' ? ww_domain : '') + cssFile.file + '"/>';
		}

		if (data.extra_js_files) data.extra_js_files.unshift(...extra_js_files);
		else data.extra_js_files = extra_js_files;
		for (const jsFile of data.extra_js_files) {
			if (/knowl/.test(jsFile.file)) continue;
			iframeContents += '<script src="' + (jsFile.external !== '1' ? ww_domain : '') + jsFile.file + '" ' +
				Object.keys(jsFile.attributes || {}).reduce((ret, key) => {
					ret += key + '="' + jsFile.attributes[key] + '" '; return ret;
				}, "") + '></script>';
		}

		iframeContents +=
			'<link rel="stylesheet" href="https://pretextbook.org/css/0.31/pretext_add_on.css"/>' +
			'<link rel="stylesheet" href="https://pretextbook.org/css/0.31/knowls_default.css"/>' +
			'<script src="' + ww_domain + '/webwork2_files/node_modules/iframe-resizer/js/iframeResizer.contentWindow.min.js"></script>' +
			`<style>
			html { overflow-y: hidden; }
			html body { background:unset; margin: 0; }
			body { font-size: initial; line-height: initial; padding:2px; }
			.hidden-content { display: none; }
			input[type="text"], input[type="radio"], label, select {
				height: auto;
				width: auto;
				max-width: unset;
				margin: 0;
				font-size: initial;
				/*font-family: sans-serif;*/
				line-height: initial;
			}
			input[type="text"] {
				padding: 1px;
				padding-inline: 2px;
				border-width: 1px;
				border-style: inset;
				border-color: rgb(133, 133, 133);
				border-radius: 0;
				box-shadow: unset;
				transition: none;
			}
			input[type="text"]:focus, input[type="text"]:active {
				box-shadow: unset;
				border-width: 1px;
				border-style: inset;
				border-radius: 4px;
				border-color: rgb(133, 133, 133);
				outline: auto;
			}
			input[type="radio"] {
				box-sizing: border-box;
				margin-block: 3px 0;
				margin-inline: 5px 3px;
				vertical-align: unset;
			}
		span.nobreak {
			white-space: nowrap;
		}
		input[type="text"].blank, input[type="text"].correct, input[type="text"].partly-correct, input[type="text"].incorrect, select.correct, select.incorrect {
			background-size: auto 100%;
			background-position: right;
			background-repeat: no-repeat;
			padding-right: 29px;
		}
		input[type="text"].blank {
			background-color: #CDF;
			background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' version='1.1' height='20px' width='20px'><text x='19' y='16' fill='%230049DB' text-anchor='end'>⚠</text></svg>");
		}
		input[type="text"].correct, select.correct, input[type="text"].correct + span.mq-editable-field {
			background-color: #8F8;
		}
		input[type="text"].correct {
			background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' version='1.1' height='20px' width='20px'><text x='19' y='16' fill='%23060' text-anchor='end'>✓</text></svg>");
		}
			padding-left: 2rem;
			background-repeat: no-repeat;
			background-position-y: center;
		}
		input[type="text"].partly-correct, input[type="text"].partly-correct + span.mq-editable-field {
			background-color: #CDF;
			background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' version='1.1' height='22px' width='30px'><text x='28' y='18' fill='%235C5C00' text-anchor='end'>⚠</text></svg>");
		}
		input[type="text"].incorrect, select.incorrect, input[type="text"].incorrect + span.mq-editable-field {
			background-color: #DAA;
		}
		input[type="text"].incorrect {
			background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' version='1.1' height='22px' width='30px'><text x='28' y='18' fill='%23943D3D' text-anchor='end'>⚠</text></svg>");
		}
		input[type="text"].partly-correct, input[type="text"].incorrect {
			background-size: auto 70%;
		}
		label {
			padding-left: 1.8em;
		}
		label.correct::before {
			color: #060;
			content: '✓';
		}
		label.incorrect::before {
			color: #943D3D;
			content: '⚠';
			font-size: small;
		}
		label.correct::before, label.incorrect::before {
			display:inline-block;
			width: 0;
			direction: rtl;
		}
		.select-wrapper.correct::before {
			color: #060;
			content: '✓';
			margin-right: 2pt;
		}
		.select-wrapper.incorrect::before {
			color: #943D3D;
			content: '⚠';
			margin-right: 2pt;
			font-size: small;
		}
		.checkboxes-container.correct label input, .checkboxes-container.incorrect label input {
			border-radius: 2px;
			appearance: none;
			-webkit-appearance: none;
			-moz-appearance: none;
			width: 20px;
			height: 20px;
			cursor: pointer;
			position: relative;
			top: 5px;
			background-repeat: no-repeat;
		}
		.checkboxes-container.correct label input {
			background-color: #8F8;
			border: #060 solid;
		}
		.checkboxes-container.correct label input:checked {
			background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' version='1.1' height='14px' width='14px'><text x='13' y='13' text-anchor='end'>✓</text></svg>");
		}
		.checkboxes-container.incorrect label input {
			background-color: #DAA;
			border: #943D3D solid;
		}
		.checkboxes-container.incorrect label input:checked {
			background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' version='1.1' height='14px' width='14px'><text x='13' y='13' text-anchor='end'>✘</text></svg>");
		}
		div.PGML img.image-view-elt {
			max-width:100%;
		}

			label {
				display: inline-block;
			}
			select {
				margin: 0;
				border-width: 1px;
				border-style: inset;
				display: inline-block;
				padding-block: 1px;
				vertical-align: baseline;
				background-color: unset;
				padding-inline: 0;
			}
			.result-popover .popover-header, .result-popover .popover-content {
				text-align: center;
			}
			.result-popover .popover-header.correct {
				background-color: #8F8;
			}
			.result-popover.nocontent .popover-header {
				border-radius: calc(.3rem - 1px);
			}
			.result-popover.nocontent .popover-header::before {
				border: none;
			}
			.accordion-body.expanded {
				overflow-y: visible;
				overflow-x: clip;
			}
			.graphtool-answer-container .graphtool-graph {
				margin: 0;
				width: 300px;
				height: 300px;
			}
			.graphtool-answer-container .graphtool-number-line {
				height: 57px;
			}
			.checkboxes-container .ww-feedback {
				position: absolute;
				left: 2px;
			}
			.graphtool-container.correct .graphtool-graph {
				background-color: #8F8;
				background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' version='1.1' height='20px' width='20px'><text x='19' y='16' fill='%23060' text-anchor='end'>✓</text></svg>");
				background-repeat: no-repeat;
			}
			.graphtool-container.incorrect .graphtool-graph {
				background-color: #DAA;
				background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' version='1.1' height='22px' width='30px'><text x='28' y='18' fill='%235C5C00' text-anchor='end'>⚠</text></svg>");
				background-repeat: no-repeat;
			}
			</style>` +
			'</head><body><main class="pretext-content">' + form.outerHTML + '</main></body>' +
			'</html>';

		let iframe;
		// If there is no action this is the initialization call.
		if (!action) {
			// Create the iframe.
			iframe = document.createElement('iframe');
			iframe.style.width = '1px';
			iframe.style.minWidth = '100%';
			iframe.classList.add('problem-iframe');

			// Hide the static problem
			ww_container.querySelector('.problem-contents').classList.add('hidden-content');

			if (activate_button != null) {
				// Make sure the iframe follows the activate button in the DOM
				activate_button.after(iframe);
			} else {
				ww_container.prepend(iframe);
			}

			iFrameResize({ checkOrigin: false, scrolling: 'omit', heightCalculationMethod: 'min' }, iframe);

			iframe.addEventListener('load', () => {
				// Set up form submission from inside the iframe.
				const iframeForm = iframe.contentDocument.getElementById(ww_id + '-form');
				iframeForm.addEventListener('submit', (e) => {
					handleWW(ww_id, "check");
					e.preventDefault();
				});

				iframe.contentDocument.querySelectorAll('.collapse.in').forEach(collapse => collapse.classList.add('expanded'));
				iframe.contentWindow.jQuery('.collapse').on('shown', function(e) { if (e.target != this) return; this.classList.add('expanded'); });
				iframe.contentWindow.jQuery('.collapse').on('hide', function(e) { if (e.target != this) return; this.classList.remove('expanded'); });

				iframe.contentDocument.querySelectorAll("button.ww-feedback[data-bs-content]").forEach(button => {
					const bsPopover = new iframe.contentWindow.bootstrap.Popover(button, {
						html: true,
						placement: 'bottom',
						fallbackPlacements: [],
						trigger: 'click',
						customClass: 'result-popover' + (button.dataset.emptyContent ? ' nocontent' : '')
					});
					bsPopover.show();
					const content = iframe.contentDocument.getElementById(button.id.replace("-feedback-button", "-content"));
					const popover = content.parentNode.parentNode;
					bsPopover.hide();

					/*button.addEventListener('shown.bs.popover', () => {
						// Note that the button itself has the aria-describedby attribute set by bootstrap automatically.
						button.previousElementSibling?.setAttribute('aria-describedby', popover.id);
					});*/

					button.addEventListener('click', () => bsPopover.show(), { once: true });

					popover.querySelector('.popover-arrow').remove();
					const title = popover.querySelector('.popover-header');
					if (button.dataset.emptyContent) content.parentNode.remove();
					if (title.textContent == localize_correct + '!') title.classList.add('correct');
				});
				iframe.contentWindow.MathJax.startup.promise.then(() => iframe.contentWindow.MathJax.typesetPromise(['.popover', '.popover-content']));
			});
		} else {
			iframe = ww_container.querySelector('.problem-iframe');
		}

		iframe.srcdoc = iframeContents;

		iframe.addEventListener('load', () => {
			// Remove the loader overlay
			loader.remove();
		}, { once: true })

		// Place focus on the problem.
		ww_container.focus()
	});
}

function WWshowCorrect(ww_id, answers) {
	const ww_container = document.getElementById(ww_id);
	const iframe = ww_container.querySelector('.problem-iframe');

	const body = iframe.contentDocument.getElementById(ww_id + '-body')
	$("body").trigger("runestone_show_correct", {
		"ww_id": ww_id,
		"answers": answers
	});

	let inputs = body.querySelectorAll("input:not([type=hidden])");
	for (const input of inputs) {
		const name = input.name;
		const span_id = `${ww_id}-${name}-correct`;

		if (input.type == 'text' && answers[name] && !(iframe.contentDocument.getElementById(span_id))) {
			const input_id = input.id;
			const mq_span = iframe.contentDocument.getElementById(`mq-answer-${input_id}`);
			if (mq_span) {
				mq_span.style.display = 'none';
			}
			const feedbackButton = iframe.contentDocument.getElementById(`${ww_id}-${name}-feedback-button`);
			if (feedbackButton) {
				iframe.contentWindow.bootstrap.Popover.getInstance(feedbackButton)?.hide();
				feedbackButton.remove();
			}
			label = iframe.contentDocument.getElementById(`${span_id}-label`);
			if (label) {
				label.parentElement.insertBefore(input, label);
				label.remove();
			}
			input.type = "hidden";
			// we need to convert things like &lt; in answers to <
			const correct_ans_text = iframe.contentDocument.createElement('div');
			correct_ans_text.innerHTML = answers[name].correct_ans;
			input.value = correct_ans_text.textContent;
			const show_span = iframe.contentDocument.createElement('span');
			show_span.id = span_id;
			show_span.appendChild(answers[name].correct_ans_latex_string
				? iframe.contentDocument.createTextNode('\\(' + answers[name].correct_ans_latex_string + '\\)')
				: iframe.contentDocument.createTextNode(answers[name].correct_ans));
			input.parentElement.insertBefore(show_span, input);
		}

		if (input.type.toUpperCase() == 'RADIO' && answers[name]) {
			const feedbackButton = iframe.contentDocument.getElementById(`${ww_id}-${name}-feedback-button`);
			if (feedbackButton) {
				iframe.contentWindow.bootstrap.Popover.getInstance(feedbackButton)?.hide();
				feedbackButton.remove();
			}
			const correct_ans = answers[name].correct_choice || answers[name].correct_ans;
			if (input.value == correct_ans) {
				input.checked = true;
				//input.setAttribute('checked', 'checked');
			} else {
				input.checked = false;
			}
		}

		if (input.type.toUpperCase() == 'CHECKBOX' && answers[name]) {
			const correct_choices = answers[name].correct_choices;
			if (correct_choices.includes(input.value)) {
				input.checked = true;
			//	input.setAttribute('checked', 'checked');
			} else {
				input.checked = false;
			//	 input.setAttribute('checked', false);
			}
		}
	}

	const hiddenInputs = body.querySelectorAll("input[type=hidden]");
	for (const input of hiddenInputs) {
		const name = input.name;
		if (!input.nextElementSibling) continue;
		const graphtoolContainer = input.nextElementSibling.nextElementSibling;
		if (graphtoolContainer && answers[name] && graphtoolContainer.classList.contains('graphtool-container')) {
			const feedbackButton = iframe.contentDocument.getElementById(`${ww_id}-${name}-feedback-button`);
			if (feedbackButton) {
				iframe.contentWindow.bootstrap.Popover.getInstance(feedbackButton)?.hide();
				feedbackButton.remove();
			}
			const correct_ans_div = iframe.contentDocument.createElement('div');
			input.parentElement.insertBefore(correct_ans_div, graphtoolContainer);
			graphtoolContainer.style.display = 'none';
			input.value = answers[name].correct_ans;
			iframe.contentWindow.jQuery(correct_ans_div).html(answers[name].correct_ans_latex_string);
			const script = iframe.contentDocument.createElement('script');
			script.textContent = correct_ans_div.querySelector('script').textContent
				.replace('\nwindow.addEventListener("DOMContentLoaded",', '(')
				.replace(/;\n$/, '();');
			iframe.contentDocument.body.appendChild(script);
		}
	}

	let selects = body.querySelectorAll("select:not([type=hidden])");
	for (const select of selects) {
		const name = select.name;
		const span_id = `${ww_id}-${name}-correct`;
		if (answers[name] && !iframe.contentDocument.getElementById(span_id)) {
			const feedbackButton = iframe.contentDocument.getElementById(`${ww_id}-${name}-feedback-button`);
			if (feedbackButton) {
				iframe.contentWindow.bootstrap.Popover.getInstance(feedbackButton)?.hide();
				feedbackButton.remove();
			}
			select.style.display = "none";
			select.value = answers[name].correct_ans;
			const show_span = iframe.contentDocument.createElement('span');
			show_span.id = span_id;
			show_span.appendChild(answers[name].correct_ans_latex_string
				? iframe.contentDocument.createTextNode('\\(' + answers[name].correct_ans_latex_string + '\\)')
				: iframe.contentDocument.createTextNode(answers[name].correct_ans));
			select.parentElement.insertBefore(show_span, select);
		}
	}

	// run MathJax on our new rendering
	// FIXME: We only need to typeset the added elements, not the entire body.
	const mathjaxTypesetScript = iframe.contentDocument.createElement('script');
	mathjaxTypesetScript.textContent = 'MathJax.startup.promise.then(() => MathJax.typesetPromise([document.body]));';
	iframe.contentDocument.body.appendChild(mathjaxTypesetScript);
}

function resetWW(ww_id) {
	const ww_container = document.getElementById(ww_id);
	const activate_button = document.getElementById(ww_id + '-button');

	ww_container.dataset.current_seed = ww_container.dataset.seed;

	iframe = ww_container.querySelector('.problem-iframe');
	iframe.remove();

	ww_container.querySelector('.problem-contents').classList.remove('hidden-content');

	ww_container.querySelector('.problem-buttons.webwork').remove();
	ww_container.querySelector('.problem-buttons').classList.remove('hidden-content');
	// if the newer activate button is there (but hidden) bring it back too
	if (activate_button != null) {activate_button.classList.remove('hidden-content');};
}

function adjustSrcHrefs(container,ww_domain) {
	container.querySelectorAll('[href]').forEach((node) => {
		const href = node.attributes.href.value;
		if (href !== '#' && !href.match(/^[a-z]+:\/\//i)) node.href = ww_domain + '/' + href;
	});
	container.querySelectorAll('[src]').forEach((node) => {
		node.src = new URL(node.attributes.src.value, ww_domain).href;
	});
}

function translateHintSol(ww_id, body_div, ww_domain, b_ptx_has_hint, b_ptx_has_solution, hint_label_text, solution_label_text) {
	// the problem text may come with "hint"s and "solution"s
	// Each one is an "a" with the class ".knowl" and the data-type attribute of either "hint" or "solution".
	// the WeBWorK knowl js would normally handle this, but we want PreTeXt knowl js to handle it
	// so we replace the "a" with the content that should be there for PTX knowl js
	// also if hint/sol were missing from the static version, we want these removed here

	const hintSols = body_div.querySelectorAll('.knowl[data-type="hint"],.knowl[data-type="solution"]');
	let solutionlikewrapper;
	for (const hintSol of hintSols) {
		const hintsolp = hintSol.parentNode;
		if (!hintsolp) continue;
		const hintsolpp = hintsolp.parentNode;  //the div that contains each p with a knowl anchor
		const hintSolType = hintSol.dataset.type;

		if (hintsolpp.querySelectorAll(".webwork.solutions").length == 0)
		{
			solutionlikewrapper = document.createElement('div');
			solutionlikewrapper.classList.add('webwork', 'solutions');
			hintsolpp.insertBefore(solutionlikewrapper, hintsolp);
		}

		if ((hintSolType == 'solution' && !b_ptx_has_solution) ||
			(hintSolType == 'hint' && !b_ptx_has_hint))
			continue;

		const knowlDetails = document.createElement('details');
		knowlDetails.classList.add(hintSolType);
		knowlDetails.classList.add('solution-like');
		knowlDetails.classList.add('born-hidden-knowl');

		const knowlSummary = document.createElement('summary');
		const summaryLabel = document.createElement('span');
		summaryLabel.classList.add('type');
		summaryLabel.innerHTML = hintSolType == 'hint' ? hint_label_text : solution_label_text;
		knowlSummary.appendChild(summaryLabel);
		knowlDetails.appendChild(knowlSummary);

		const knowlContents = document.createElement('div');
		knowlContents.classList.add(hintSolType);
		knowlContents.classList.add('solution-like');
		knowlContents.innerHTML = hintsolp.firstElementChild.dataset.knowlContents;
		knowlDetails.appendChild(knowlContents);

		adjustSrcHrefs(knowlContents, ww_domain)
		solutionlikewrapper.appendChild(knowlDetails);
	}
	for (const hintSol of hintSols) {
		hintSol.parentNode?.remove();
	}
}

function cloneAttributes(target, source) {
	[...source.attributes].forEach( attr => { target.setAttribute(attr.nodeName ,attr.nodeValue) });
}

function createFeedbackButton(id, title, content) {
	const feedbackButton = document.createElement('button');
	feedbackButton.dataset.bsTitle = title;
	feedbackButton.dataset.bsContent = `<div id="${id}-content">${content || ''}</div>`;
	if (!content) feedbackButton.dataset.emptyContent = '1';
	const contentSpan = document.createElement('span');
	contentSpan.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" width="20px" height="20px" fill="none" stroke-width="2" viewBox="0 0 24 24" color="#000000"><path stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" d="M12 11.5v5M12 7.51l.01-.011M12 22c5.523 0 10-4.477 10-10S17.523 2 12 2 2 6.477 2 12s4.477 10 10 10Z"></path></svg>`;
	feedbackButton.appendChild(contentSpan);
	feedbackButton.type = 'button';
	feedbackButton.classList.add('ww-feedback');

	feedbackButton.id = `${id}-feedback-button`;
	feedbackButton.dataset.bsToggle = 'popover';

	return feedbackButton;
}

function webworkSeedHash(string) {
	var hash = 0, i, chr;
	if (string.length === 0) return hash;
	for (i = 0; i < string.length; i++) {
		chr   = string.charCodeAt(i);
		hash  = ((hash << 5) - hash) + chr;
		hash |= 0; //Convert to 32bit integer
	}
	return Math.abs(hash);
};
