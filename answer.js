
function escapeHTML(text) {
    the_ans = text;
    the_ans = the_ans.replace(/&/g, "&amp;");
    the_ans = the_ans.replace(/<([a-zA-Z])/g, '< $1');

    return the_ans
}
function uNescapeHTML(text) {
    the_ans = text;
    the_ans = the_ans.replace(/&lt; /g, "<");
    the_ans = the_ans.replace(/&lt;/g, "<");
    the_ans = the_ans.replace(/&gt;/g, ">");
    the_ans = the_ans.replace(/&amp;/g, "&");
    the_ans = the_ans.replace(/<([a-zA-Z])/g, "< $1");

    return the_ans
}

function dollars_to_slashparen(text) {
    the_ans = text;
    the_ans = the_ans.replace(/(^|\s|-)\$([^\$\f\r\n]+)\$(\s|\.|,|;|:|\?|!|$)/g, "$1\\($2\\)$3");
       //twice, for $5$-$6$
    the_ans = the_ans.replace(/(^|\s|-)\$([^\$\f\r\n]+)\$(\s|\.|,|;|:|\?|!|-|$)/g, "$1\\($2\\)$3");

    return the_ans
}

var reading_questions = document.querySelectorAll("section.reading-questions article.exercise-like");

console.log('reading_questions.length', reading_questions.length);

function make_submit_button() {
    if (document.getElementById("rq_submit")) {  // don't make the button if it already exists
        console.log("button exists", document.getElementById("rq_submit"));
        return
    }
    last_reading_question = reading_questions[reading_questions.length - 1];
    answer_button_holder = document.createElement('div');
    answer_button_holder.setAttribute('class', 'rq_submit_wrapper');
    answer_button_holder.innerHTML = rq_submit_button;
    last_reading_question.insertAdjacentElement("afterend", answer_button_holder);
}

function save_reading_questions() {
    rq_data = {"action": "save", "user": uname, "pw": emanu, "pI": pageIdentifier, "type": "readingquestions", "rq": JSON.stringify(reading_questions_object)}
    $.ajax({
    url: "https://aimath.org/cgi-bin/u/highlights.py",
    type: "post",
    data: JSON.stringify(rq_data),
    dataType: "json",
    success: function(data) {
        console.log("something", data, "back from highlight");
        alert(data);
    },
   error: function(errMsg) {
      console.log("seems to be an error?",errMsg);
      alert("Error\n" + errMsg);
   }
});

  console.log("just ajax sent", JSON.stringify(reading_questions_object));
}

// no point in handling reading questions if there are not any
if (reading_questions.length) {

  // retrieve the existing reading questions, if they exist
  var reading_questions_object_id = pageIdentifier + "___" + "rq";
  var reading_questions_object = localStorage.getObject(reading_questions_object_id);
  var reading_questions_all_answered = false;
  var reading_questions_submitted = false;

  if (!reading_questions_object) {
      reading_questions_object = {}
  }

  if (Object.keys(reading_questions_object).length == reading_questions.length) {
      console.log("all reading questions have previously been answered");
      reading_questions_all_answered = true;
  }

  answer_css = document.createElement('style');
  answer_css.type = "text/css";
  answer_css.id = "highlight_css";
  document.head.appendChild(answer_css);
  var css_for_ans = '#rq_submit { background: #FDD; padding: 3px 5px; border-radius: 0.5em}\n';
  css_for_ans += '#rq_submit.submitted { background: #EFE; color: #BBB}';
  css_for_ans += '.rq_submit_wrapper { margin-top: 0.5em; float: right}';
  answer_css.innerHTML = css_for_ans;

  var rq_answer_label = '<span'
  rq_answer_label += ' class="readingquestion_make_answer addcontent';
  rq_answer_label += ' ' + role + '"';
  rq_answer_label += ' style="margin-left:1em; font-size:80%; color:#a0a;"';
  rq_answer_label += '>';
  if (role == "instructor") {
      rq_answer_label += 'Responses';
  } else {
      rq_answer_label += 'My answer&rarr;';
  }
  rq_answer_label +='</span>';

  var rq_submit_button = '<span';
  rq_submit_button += ' class="submit"';
  rq_submit_button += ' id="rq_submit"';
  rq_submit_button += '>';
  rq_submit_button += 'Submit answers';
  rq_submit_button +='</span>';

  // make reading quesitons active, and insert answers if available
  for (var j=0; j < reading_questions.length; ++j) {
      var reading_question = reading_questions[j];
      var reading_question_id = reading_question.id;
  
      rq_answer_id = reading_question_id + "_text";
 //     var existing_content = localStorage.getObject(rq_answer_id);
      var existing_content = reading_questions_object[rq_answer_id];
  
      if (reading_question.lastElementChild.tagName === "P") {
          console.log("ends in a p");
          reading_question.lastElementChild.innerHTML += rq_answer_label;
      } else {
         var this_answer_link = document.createElement('div');
         this_answer_link.innerHTML = rq_answer_label;
         reading_question.insertAdjacentElement("afterend", this_answer_link);
      }
      if (existing_content) {
         $('#'+reading_question_id).find(".readingquestion_make_answer").addClass("hidecontrols");
  
         var this_rq_id_text = reading_question_id + "_text";
         var this_rq_id_controls = reading_question_id + "_controls";
         var answer_div = '<div';
         answer_div += ' id="' + this_rq_id_text + '"';
         answer_div += ' class="given_answer has_am"';
         answer_div += '>';
         answer_div += dollars_to_slashparen(escapeHTML(existing_content)) + " ";
         answer_div += '</div>';
  
  /* need to save the original so that MathJax does not change it */
         var hidden_answer_div = '<div';
         hidden_answer_div += ' id="' + this_rq_id_text + '_hidden' + '"';
         hidden_answer_div += ' class="tex2jax_ignore asciimath2jax_ignore" style="display: none">';
         hidden_answer_div += escapeHTML(existing_content);
         hidden_answer_div += '</div>';
  
  
         var this_rq_controls = '<div id="' + this_rq_id_controls + '" class="input_controls hidecontrols" style="margin-bottom:-1.9em;">';
         this_rq_controls += '<span class="action clear_item rq_delete">delete</span>';
         this_rq_controls += '<span class="action save_item rq_edit">edit</span>';
         this_rq_controls += '<span class="action amhelp">how to write math</span>';
         this_rq_controls += '</div>'
  
         var this_rq_answer_and_controls = document.createElement('div');
         this_rq_answer_and_controls.setAttribute('style', 'width:80%; margin-left:auto; margin-right:auto; margin-top:0.5em;');
         this_rq_answer_and_controls.setAttribute('class', 'rq_answer');
         this_rq_answer_and_controls.innerHTML = hidden_answer_div + answer_div + this_rq_controls;
         $('#'+reading_question_id).append(this_rq_answer_and_controls);
       //  this.parentNode.insertAdjacentElement("afterend", this_rq_answer_and_controls);
  
      }
  
  }
  /* typeset the math in the reading questions answers */
  MathJax.Hub.Queue(["Typeset",MathJax.Hub]);
  
  /* make a new blank area to answer a question */
  $('.readingquestion_make_answer').mousedown(function(e){
    console.log(".readingquestion_make_answer");
    $(this).addClass("hidecontrols");
    var this_rq_id = this.parentNode.parentNode.id;
    var this_rq_id_text = this_rq_id + "_text";
    var this_rq_id_controls = this_rq_id + "_controls";
    console.log(".rq", this_rq_id);
    answer_textarea = '<textarea';
    answer_textarea += ' id="' + this_rq_id_text + '"'
    answer_textarea += ' rows="' + '3' + '"';
    answer_textarea += ' style="width:100%; height: 63px;"';
    answer_textarea += '>';
    answer_textarea += '</textarea>';
  
    var this_rq_controls = '<div id="' + this_rq_id_controls + '" class="input_controls" style="margin-bottom:-1.9em;">';
    this_rq_controls += '<span class="action clear_item rq_delete">delete</span> <span class="action save_item rq_save">save</span>';
    this_rq_controls += '</div>'
  
    var this_rq_answer_and_controls = document.createElement('div');
    this_rq_answer_and_controls.setAttribute('style', 'width:80%; margin-left:auto; margin-right:auto; margin-top:0.5em;');
  
    this_rq_answer_and_controls.innerHTML = answer_textarea + this_rq_controls;
    this.parentNode.insertAdjacentElement("afterend", this_rq_answer_and_controls);
  
  //  MathJax.Hub.Queue(["Typeset",MathJax.Hub]);
  
    console.log("adding other keypress listener");
    var this_textarea = document.getElementById(this_rq_id_text);
    this_textarea.addEventListener("keypress", function() {
  //     if(this_textarea.scrollTop != 0){
          this_textarea.style.height = this_textarea.scrollHeight + "px";
  //     }
       }, false);
  
  });
  
  /* save a reading question */
  $('body').on('click','.rq_save', function(){
    console.log(".rq_save");
    var this_rq_id = this.parentNode.previousSibling.id;
    var this_rq_ans = this.parentNode.previousSibling;
    console.log(".rq_save", this_rq_id);
    var this_rq_text = this_rq_ans.value;
    this_rq_text = this_rq_text.trim();
  // we have the contents of the answer, so save it to local storage
    reading_questions_object[this_rq_id] = this_rq_text;
    localStorage.setObject(reading_questions_object_id, reading_questions_object);
    if (Object.keys(reading_questions_object).length == reading_questions.length) {
        console.log("all reading questions have been answered");
        reading_questions_all_answered = true;
        make_submit_button();
    }
  
  // and save a copy hidden on the page
    console.log("looking for", this_rq_id + "_hidden");
  // when the initial answer box is created, there is no hidden version
    if ( !document.getElementById(this_rq_id + "_hidden")) {
       var hidden_answer_div = document.createElement('div');
        hidden_answer_div.setAttribute('id', this_rq_id + '_hidden');
        hidden_answer_div.setAttribute('class', 'tex2jax_ignore asciimath2jax_ignore');
        hidden_answer_div.setAttribute('style', 'display: none');
        this_rq_ans.insertAdjacentElement("beforebegin", hidden_answer_div);
    }
    document.getElementById(this_rq_id + "_hidden").innerHTML = escapeHTML(this_rq_text);
  
  //and show it on the page
    var this_ans_static = document.createElement('div');
    this_ans_static.setAttribute('id', this_rq_id);
    this_ans_static.setAttribute('class', 'given_answer has_am');
    this_ans_static.innerHTML = dollars_to_slashparen(escapeHTML(this_rq_text)) + " "
    this_rq_ans.replaceWith(this_ans_static);
  
    MathJax.Hub.Queue(["Typeset",MathJax.Hub]);
  
    $(this).parent().addClass("hidecontrols");
  
    $(this).parent().parent().addClass("rq_answer");
  
    var edit_button = document.createElement('span');
    edit_button.setAttribute('class', "action edit_item rq_edit");
    edit_button.innerHTML = "edit";
    this.replaceWith(edit_button);
  });
  
  /* edit an existing answer */
  $('body').on('click','.rq_edit', function(){
    console.log(".rq_edit");
    var this_rq_id = this.parentNode.previousSibling.id;
    var this_rq_ans = this.parentNode.previousSibling;
    console.log(".rq_edit", this_rq_id);
    var this_rq_text = this_rq_ans.innerHTML;
    var this_rq_text_raw = uNescapeHTML(document.getElementById(this_rq_id + "_hidden").innerHTML);
  
     //this is copied from above.  need to eliminate repeated code
  
    var answer_textarea_editable = document.createElement('textarea');
    answer_textarea_editable.setAttribute('id', this_rq_id);
    answer_textarea_editable.setAttribute('rows', '3');
    answer_textarea_editable.setAttribute('style', 'width:100%; height: 44px;');
  
    this_rq_ans.replaceWith(answer_textarea_editable);
  
    $(this).parent().removeClass("hidecontrols");
  
    $(this).parent().parent().removeClass("rq_answer");
  
    var save_button = document.createElement('span');
    save_button.setAttribute('class', "action edit_item rq_save");
    save_button.innerHTML = "save";
    this.replaceWith(save_button);
  
    $('#' + this_rq_id).val(this_rq_text_raw);
  
    answer_textarea_editable.style.height = answer_textarea_editable.scrollHeight + "px";
    answer_textarea_editable.addEventListener("keypress", function() {
  //     if(answer_textarea_editable.scrollTop != 0){
          answer_textarea_editable.style.height = answer_textarea_editable.scrollHeight + "px";
  //     }
       }, false);
  });
  
  $('body').on('mouseover','.rq_answer', function(){
    $(this).children().last().removeClass("hidecontrols");
    $(this).attr('z-index', '2000');
  });
  $('body').on('mouseleave','.rq_answer', function(){
    $(this).children().last().addClass("hidecontrols");
    $(this).attr('z-index', '');
  });
  
  $('body').on('click','.rq_delete', function(){
    console.log(".rq_delete");
    var this_rq_id = this.parentNode.previousSibling.id;
    console.log(".rq_delete", this_rq_id);
    $(this).parent().parent().prev().children(".readingquestion_make_answer").removeClass("hidecontrols");
    $(this).parent().parent().remove();
    console.log("reading_questions_object", reading_questions_object);
    delete reading_questions_object[this_rq_id];
    console.log("now reading_questions_object", reading_questions_object);
 //   localStorage.removeItem(this_rq_id);
    localStorage.setObject(reading_questions_object_id, reading_questions_object);
  });
  
  $('body').on('click','#rq_submit', function(){
    console.log("submitting rq answers");
    $('#rq_submit').addClass('submitted');
    document.getElementById('rq_submit').textContent = "Resubmit answers";
    save_reading_questions();
  });

  $('body').on('click','.amhelp', function(){
     var amhelpmessage = "Write math formulas as AsciiMath inside backticks:\n`math goes here`.";
     amhelpmessage += "           For example:\nThe Pythagorean theorem says `sin^2(x) + cos^2(x) = 1`,\n";
     amhelpmessage += "and the quadratic formula is `x = (-b +- sqrt(b^2 - 4ac))/(2a)`. \n";
     amhelpmessage += "Note the use of parentheses for grouping.\n";
     amhelpmessage += "Visit http://asciimath.org for a list of AsciiMath commands.\n\n";
     amhelpmessage += "You can also use LaTeX, with either slash-parentheses \\(...\\)\n";
     amhelpmessage += "or dollar signs $...$ as delimeters for inline math.";
     alert(amhelpmessage)
  });

  if(reading_questions_all_answered) {
        make_submit_button();
  }
}
