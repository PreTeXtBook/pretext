
function escapeHTML(text) {
    if (!text) { return "" }
    the_ans = text;
    the_ans = the_ans.replace(/&/g, "&amp;");
    the_ans = the_ans.replace(/<([a-zA-Z])/g, '< $1');

    return the_ans
}
function uNescapeHTML(text) {
    if (!text) { return "" }
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

/*  The structure of a reading question is an erticle with an id (this_ques_id),
    containing:
       #this_ques_id_text    the answer given (in a div with that id)
       #this_ques_id_text_hidden   the answer in a raw form (in a hidden div)
       #this_ques_id_text_input    the answer in a textinput with that id

    Try to do all operations by id, and not by carrying objects around.
*/

var reading_questions = document.querySelectorAll("section.reading-questions article.exercise-like, #boelkins-ACS .main #content > section:first-of-type > section:first-of-type > .project-like li");

var reading_answers = {};

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

  if (Object.keys(reading_questions_object).length >= reading_questions.length) {
    console.log("Object.keys(reading_questions_object)",Object.keys(reading_questions_object));
    console.log("reading_questions", reading_questions);
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

  rq_answer_label = '<span'
  rq_answer_label += ' class="readingquestion_make_answer addcontent';
  rq_answer_label += ' ' + role + '"';
//  rq_answer_label += ' style="margin-left:1em; font-size:80%; color:#a0a;"';
  rq_answer_label += '>';
  if (role == "instructor") {
      rq_answer_label += 'Responses&rarr;';
  } else {
      rq_answer_label += 'Click twice to edit...';
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
  
      if (existing_content && role == "student") {
         $('#'+reading_question_id).find(".readingquestion_make_answer").addClass("hidecontrols");
  
         var this_ques_id_text = reading_question_id + "_text";
         var this_ques_id_controls = reading_question_id + "_controls";
         var answer_div = '<div';
         answer_div += ' id="' + this_ques_id_text + '"';
         answer_div += ' class="given_answer has_am process-math processme"';
         answer_div += '>';
         answer_div += dollars_to_slashparen(escapeHTML(existing_content)) + " ";
         answer_div += '</div>';
  
  /* need to save the original so that mathjax does not change it */
         var hidden_answer_div = '<div';
         hidden_answer_div += ' id="' + this_ques_id_text + '_hidden' + '"';
         hidden_answer_div += ' class="tex2jax_ignore asciimath2jax_ignore" style="display: none">';
         hidden_answer_div += escapeHTML(existing_content);
         hidden_answer_div += '</div>';
  
  
         var this_rq_controls = '<div id="' + this_ques_id_controls + '" class="input_controls hidecontrols">';
         this_rq_controls += '<span class="action save_item rq_save">preview</span>';
//         this_rq_controls += '<span class="action clear_item rq_delete">delete</span>';
         this_rq_controls += '<span class="action amhelp">typing math?</span>';
         this_rq_controls += '</div>'
  
         var this_rq_answer_and_controls = document.createElement('div');
         this_rq_answer_and_controls.setAttribute('style', 'width:80%; padding-left:10%; padding-right:10%; margin-top:0.5em;');
         this_rq_answer_and_controls.setAttribute('class', 'rq_answer');
         this_rq_answer_and_controls.innerHTML = hidden_answer_div + answer_div + this_rq_controls;
         console.log("appending to ", reading_question_id);
         $('#'+reading_question_id).append(this_rq_answer_and_controls);
       //  this.parentNode.insertAdjacentElement("afterend", this_rq_answer_and_controls);
  
          /* typeset the math in the reading questions answers */
   //       MathJax.Hub.Queue(["Typeset",MathJax.Hub]);
         if (mjvers && mjvers < 3) {
              MathJax.Hub.Queue(['Typeset', MathJax.Hub]);
         } else if (mjvers > 3) {
              MathJax.typesetPromise();
         }
  
      }  else if(role == "instructor" || role == "student") {

         var this_answer_link = document.createElement('div');
         this_answer_link.innerHTML = rq_answer_label;
         console.log("inserting afterend of",reading_question);
    //     reading_question.insertAdjacentElement("afterend", this_answer_link);
         reading_question.append(this_answer_link);
      }  else  {

      console.log("should not be here");

      }
  
  }
  
  function allow_student_answers(){
  /* make a new blank area to answer a question */
  $('.readingquestion_make_answer.student').mousedown(function(e){
    console.log(".readingquestion_make_answer student");
//    $(this).addClass("hidecontrols");
 //   var this_ques_id = this.parentNode.parentNode.id;
    var this_ques_id = this.parentNode.parentNode.id;
    var this_ques_id_text = this_ques_id + "_text";
    var this_ques_id_controls = this_ques_id + "_controls";
    console.log(".rq", this_ques_id);
    answer_textarea = '<textarea';
    answer_textarea += ' class="rq_answer_text"'
    answer_textarea += ' id="' + this_ques_id_text + '_input"'
    answer_textarea += ' rows="' + '3' + '"';
    answer_textarea += ' style="width:95%; height: 63px;"';
    answer_textarea += '>';
    answer_textarea += '</textarea>';
  
    var this_rq_controls = '<div id="' + this_ques_id_controls + '" class="input_controls" style="margin-bottom:-1.9em;">';
    this_rq_controls += '<span class="action save_item rq_save">preview</span>';
//    this_rq_controls += '<span class="action clear_item rq_delete">delete</span>';
    this_rq_controls += '<span class="action amhelp">typing math?</span>';
    this_rq_controls += '</div>'
  
    var this_rq_answer_and_controls = document.createElement('div');
    this_rq_answer_and_controls.setAttribute('class', 'rq_answer editing');
    this_rq_answer_and_controls.setAttribute('style', 'width:80%; padding-left:10%; padding-right:10%; margin-top:0.5em;');
  
    this_rq_answer_and_controls.innerHTML = answer_textarea + this_rq_controls;
    this.parentNode.insertAdjacentElement("afterend", this_rq_answer_and_controls);

    this.remove();
  
  //  MathJax.Hub.Queue(["Typeset",MathJax.Hub]);
  
    console.log("adding other keypress listener");
    var this_textarea = document.getElementById(this_ques_id_text + "_input");
    console.log("to", this_textarea);
    this_textarea.addEventListener("keypress", function() {
  //     if(this_textarea.scrollTop != 0){
     //     console.log("this_textarea.scrollHeight", this_textarea.scrollHeight, "this_textarea.scrollTop", this_textarea.scrollTop);
     //     console.log("this_textarea.clientHeight", this_textarea.clientHeight);
          this_textarea.overflow = "scroll";
     //     console.log("this_textarea.scrollHeight", this_textarea.scrollHeight, "this_textarea.scrollTop", this_textarea.scrollTop);
     //     console.log("this_textarea.clientHeight", this_textarea.clientHeight);
          this_textarea.overflow = "hidden";
     //     console.log("this_textarea.scrollHeight", this_textarea.scrollHeight, "this_textarea.scrollTop", this_textarea.scrollTop);
     //     console.log("this_textarea.getBoundingClientRect()", this_textarea.getBoundingClientRect());
          this_textarea.style.height = this_textarea.scrollHeight + "px";
  //     }
       }, false);
  var tmp_id = this_ques_id_text + "_input";
  console.log("want focus to ", tmp_id);
  console.log("which is ", $("#" +tmp_id));
  console.log("the active ", document.hasFocus(),  "element is", document.activeElement);
  console.log("or maybe it is ", $(":focus"));
  $("#" + tmp_id).focus();
  document.getElementById(tmp_id).focus();
  console.log("the active ", document.hasFocus(),  "element is", document.activeElement);
  });
  }
  allow_student_answers();

  $('.readingquestion_make_answer.instructor').mousedown(function(e){
    console.log(".readingquestion_make_answer instructor", "instId", uname, "pI", pageIdentifier);
    if (jQuery.isEmptyObject(reading_answers) || this.classList.contains("reload")) {
        rq_data = {"action": "retrieve", "instId": uname, "pw": emanu, "pI": pageIdentifier, "type": "readingquestions"};
  //    myjson = {"action": "retrieve", "type": "readingquestions", "instId": "100002000", "pI": "beezer-FCLA___FPm"}

        $.ajax({
          url: "https://aimath.org/cgi-bin/u/highlights.py",
          type: "post",
          data: JSON.stringify(rq_data),
          dataType: "json",
          async: false,
          success: function(data) {
            reading_answers = data;  
 //           console.log("something", data, "back from highlight");
 //           alert(data);
          },
          error: function(errMsg) {
            console.log("seems to be an error?",errMsg);
            alert("Error\n" + errMsg);
          }
        });
   }
//   var this_ques_id = this.parentNode.previousSibling.id;
   var this_ques_id = this.parentNode.parentNode.id;
   console.log("this_ques_id", this_ques_id);
   var compiled_answers = "";
   var title_of_this_section = $("section > h2 > .title").html();
   title_of_this_section = title_of_this_section.replace(/ /g, "%20");
   title_of_this_section = title_of_this_section.replace(/\?/g, "");
   var number_of_this_rq = 1 + $("#" + this_ques_id).index(".exercise-like");
//   console.log("first title_of_this_section", title_of_this_section);
//   console.log("first title_of_this_section.html()", title_of_this_section.html());
//   console.log("second title_of_this_section[0]", title_of_this_section[0]);
   for(var j=0; j < reading_answers.length; ++j) {
       var this_answer_all = reading_answers[j];
       var this_student_id = this_answer_all[0];
       var these_specific_answers = JSON.parse(this_answer_all[1]);
       console.log("these_specific_answers",  these_specific_answers);
       console.log("this_answer_all[2]", this_answer_all[2]);
       var this_submitted_time = JSON.parse(this_answer_all[2]);
 //      var this_submitted_time = this_answer_all[2];
       console.log("looking for this answer:", this_ques_id + "_text");
       var this_specific_answer = these_specific_answers[this_ques_id + "_text"];
       console.log("this_answer_all",this_answer_all);
       console.log("j",j,"this_specific_answer", this_specific_answer);
       console.log("this_specific_time", this_submitted_time);
       this_specific_answer = dollars_to_slashparen(escapeHTML(this_specific_answer))
       if (!this_specific_answer) {
           this_specific_answer = "no answer submitted";
           compiled_answers += '<div class="one_answer noanswer">';
       } else {
           compiled_answers += '<div class="one_answer">';
       }
       if (this_student_id.indexOf('@') > -1) {
            this_student_id = '<a href="mailto:' + this_student_id + '?Subject=RQ' + number_of_this_rq + '%20of%20' + title_of_this_section +'">' + this_student_id + '</a>';
       }
       compiled_answers += '<div class="s_id">' + this_student_id + '</div>';
       compiled_answers += '<div class="rq_sub_time">' + this_submitted_time + '</div>';
       compiled_answers += '<div class="s_ans has_am process-math processme">' + this_specific_answer + '</div>';
       compiled_answers += '</div>\n';
       console.log(j, "j", these_specific_answers)
   }
   // if the answers are being reloaded, remove the previous answers
   $("#" + this_ques_id + "_ans").remove();
   var answers_to_this_question = document.createElement('div');
   answers_to_this_question.setAttribute('class', 'compiled_answers');
   answers_to_this_question.setAttribute('id', this_ques_id + "_ans");

//         this_rq_answer_and_controls.setAttribute('style', 'width:80%; margin-left:auto; margin-right:auto; margin-top:0.5em;');
//         this_rq_answer_and_controls.setAttribute('class', 'rq_answer');
   answers_to_this_question.innerHTML = compiled_answers;
   $('#'+this_ques_id).append(answers_to_this_question);
//   this.parentNode.remove();
   this.innerHTML = "Reload responses";
   $(this).addClass("reload");
//   MathJax.Hub.Queue(["Typeset",MathJax.Hub]);
         if (mjvers && mjvers < 3) {
              MathJax.Hub.Queue(['Typeset', MathJax.Hub]);
         } else if (mjvers > 3) {
              MathJax.typesetPromise();
         }

       //  this.parentNode.insertAdjacentElement("afterend", this_rq_answe

  });


  function save_one_reading_question(this_ques_id) {
    this_ques_id_text = this_ques_id + "_text";
    var this_ans_text = $("#" + this_ques_id_text + "_input");
    console.log("the value:", this_ans_text.value);
//    var this_ques_id = this_ans.parentNode.previousSibling.previousSibling.id;
 //   var this_ques_id = this_ans.id;
    console.log("this_ques_id", this_ques_id);
//    console.log("this_rq_ans", this_rq_ans);
    var this_ans_text_value = this_ans_text.val();
    console.log("this_ans_text_value", this_ans_text_value);
    if ( /[^\x00-\x7F]/.test(this_ans_text_value)) {
        this_ans_text_value = this_ans_text_value.replace(/[^\x00-\x7F]/g, "XX");
        alert("Illegal characters in answer have been replaced by XX");
    }
    this_ans_text_value = $.trim(this_ans_text_value);   // jQuery trim (some chrome on windows had trouble with trim)
  // we have the contents of the answer, so save it to local storage
    console.log("saving in local storage at", this_ques_id_text, "the answer", this_ans_text_value);
    reading_questions_object[this_ques_id_text] = this_ans_text_value;
    localStorage.setObject(reading_questions_object_id, reading_questions_object);
    console.log("Object.keys(reading_questions_object)",Object.keys(reading_questions_object));
    console.log("reading_questions", reading_questions);
    if (Object.keys(reading_questions_object).length >= reading_questions.length && uname != "guest" && role=="student") {
        console.log("all reading questions have been answered");
        reading_questions_all_answered = true;
        make_submit_button();
    }
  
  // and save a copy hidden on the page
    console.log("looking for", this_ques_id + "_text_hidden");
  // when the initial answer box is created, there is no hidden version
    if ( !document.getElementById(this_ques_id + "_text_hidden")) {
       console.log("making a place to hide the answer");
       var hidden_answer_div = document.createElement('div');
        hidden_answer_div.setAttribute('id', this_ques_id + '_text_hidden');
        hidden_answer_div.setAttribute('class', 'tex2jax_ignore asciimath2jax_ignore');
        hidden_answer_div.setAttribute('style', 'display: none');
        console.log("this_ans_text", this_ans_text);
        document.getElementById(this_ques_id_text + "_input").insertAdjacentElement("beforebegin", hidden_answer_div);
 //       hidden_answer_div.insertBefore(this_ans_text);
    }
    console.log("hiding the raw answer in", this_ques_id + "_text_hidden");
    document.getElementById(this_ques_id + "_text_hidden").innerHTML = escapeHTML(this_ans_text_value);
  
  //and show it on the page
    var this_ans_static = document.createElement('div');
    this_ans_static.setAttribute('id', this_ques_id_text);
    this_ans_static.setAttribute('class', 'given_answer has_am process-math processme');
    console.log("setting this_ans_static.innerHTML to", dollars_to_slashparen(escapeHTML(this_ans_text_value)));
    this_ans_static.innerHTML = dollars_to_slashparen(escapeHTML(this_ans_text_value)) + " "

//    this_rq_ans.replaceWith(this_ans_static);
    console.log("about to replace  this_ans_text",  this_ans_text);
    this_ans_text.replaceWith(this_ans_static);
  
//    MathJax.Hub.Queue(["Typeset",MathJax.Hub]);
         if (mjvers && mjvers < 3) {
              MathJax.Hub.Queue(['Typeset', MathJax.Hub]);
         } else if (mjvers > 3) {
              MathJax.typesetPromise();
         }

  
    console.log(" this_ans_text",  this_ans_text);

    console.log("this_ans_static", this_ans_static);
  
    $(this_ans_static).parent().addClass("rq_answer");

    $('#' + this_ques_id + "_controls").addClass("hidecontrols");
//    $(this_q).parent().parent().addClass("rq_answer");
  
/*
    var edit_button = document.createElement('span');
    edit_button.setAttribute('class', "action edit_item rq_edit");
    edit_button.innerHTML = "edit";
    this.replaceWith(edit_button);
*/
  };
  
  /* edit an existing answer */
  function edit_one_reading_question(this_ans) {
    console.log(".rq_edit", this_ans);
 //   var this_ques_id = this.parentNode.previousSibling.id;
    var this_ques_id = this_ans.parentNode.parentNode.id;
    console.log("edditing this_ques_id", this_ques_id);
    var this_ques_id_text = this_ques_id + "_text";
 //   var this_rq_ans = this.parentNode.previousSibling;
    var this_rq_ans = this_ans;
//    var this_rq_ans_id = this_ans.id;
    console.log("now this_ques_id_text", this_ques_id_text);
    console.log(".rq_edit", this_ques_id);
    console.log("this_rq_ans", this_rq_ans);
    var this_rq_text = this_rq_ans.innerHTML;
    console.log("looking for", this_ques_id + "_hidden");
    var this_rq_text_raw = uNescapeHTML(document.getElementById(this_ques_id + "_text_hidden").innerHTML);
    console.log("this_rq_text_raw",this_rq_text_raw);
  
     //this is copied from above.  need to eliminate repeated code
  
    var answer_textarea_editable = document.createElement('textarea');
    answer_textarea_editable.setAttribute('id', this_ques_id_text + "_input");
    answer_textarea_editable.setAttribute('class', 'rq_answer_text');
    answer_textarea_editable.setAttribute('rows', '3');
    answer_textarea_editable.setAttribute('style', 'width:95%; height: 44px;');
  
    this_rq_ans.replaceWith(answer_textarea_editable);
  
    console.log("this_ans is",this_ans);
    console.log("adding editing to the parent of thing with id", this_ques_id_text, "which is the parent of", $('#' + this_ques_id_text));
    $('#' + this_ques_id_text + "_input").parent().addClass("editing");

    $('#' + this_ques_id + "_controls").removeClass("hidecontrols");
  
// WHY?    $(this).parent().parent().removeClass("rq_answer");
  
/*    var save_button = document.createElement('span');
    save_button.setAttribute('class', "action edit_item rq_save");
    save_button.innerHTML = "save";
    this.replaceWith(save_button);
*/
  
    $('#' + this_ques_id + "_text_input").val(this_rq_text_raw);
  
    answer_textarea_editable.style.height = answer_textarea_editable.scrollHeight + "px";
    answer_textarea_editable.addEventListener("keypress", function() {
  //     if(answer_textarea_editable.scrollTop != 0){
          answer_textarea_editable.style.height = answer_textarea_editable.scrollHeight + "px";
  //     }
       }, false);
  };


/* handle saving when leaving an answer box, or editing an existing answer
   when hovering over an existing answer */
  
  $('body').on('click','.given_answer', function(){
//    $(this).children().last().removeClass("hidecontrols");
    edit_one_reading_question(this);
    $(this).attr('z-index', '2000');
  });

  $('body').on('mousedown','.rq_save', function(){
//    $(this).children().last().addClass("hidecontrols");
//    $(this).attr('z-index', '');
  //  var this_rq = $(this).find(".given_answer");
//ooooooooo    var this_ques_id = this.parentNode.id;
    var this_ques_id = this.parentNode.parentNode.parentNode.id;
    console.log("id of this quesiton", this_ques_id);
//    var this_rq = $(this).find(".rq_answer_text");
//    console.log("this_rq iiIIIIII", this_rq);
    var this_current_answer = document.getElementById(this_ques_id + "_text_input");
    console.log("this_current_answer", this_current_answer);
    console.log("this_current_answer.value", this_current_answer.value);
 //   console.log("this_rq IIIIiiii value", this_rq.value);
//    save_one_reading_question(this_rq.parentNode.id);
    save_one_reading_question(this_ques_id);
    console.log("left answer area");
    $(this).removeClass("editing");
  });
  
  $('body').on('click','.rq_delete', function(){
    console.log(".rq_delete");
    var this_ques_id = this.parentNode.parentNode.parentNode.id;
    console.log(".rq_delete", this_ques_id);
    $('#' + this_ques_id + "_controls").removeClass("hidecontrols");
//and now put in controls
    var this_answer_link = document.createElement('div');
    this_answer_link.innerHTML = rq_answer_label;
    console.log("inserting afterend of",reading_question);
 //     reading_question.insertAdjacentElement("afterend", this_answer_link);
    $(this).parent().parent().replaceWith(this_answer_link);
    allow_student_answers();


    console.log("reading_questions_object", reading_questions_object);
    console.log("this_ques_id + _text", this_ques_id + "_text");
    delete reading_questions_object[this_ques_id + "_text"];
    console.log("now reading_questions_object", reading_questions_object);
 //   localStorage.removeItem(this_ques_id);
    localStorage.setObject(reading_questions_object_id, reading_questions_object);
  });
  
  if(reading_questions_all_answered && uname != "guest" && role=="student") {
        make_submit_button();
        console.log("made submit button");
  }

  $('body').on('click','#rq_submit', function(){
    console.log("submitting rq answers");
    $('#rq_submit').addClass('submitted');
    document.getElementById('rq_submit').textContent = "Resubmit answers";
    save_reading_questions();
  });

  $('body').on('click','.amhelp', function(){
     var amhelpmessage = "Write math formulas as AsciiMath inside `backticks`.\n";
     amhelpmessage += "For example:\nThe Pythagorean theorem says `sin^2(x) + cos^2(x) = 1`,\n";
     amhelpmessage += "The quadratic formula is `x = (-b +- sqrt(b^2 - 4ac))/(2a)`. \n";
     amhelpmessage += "Note the use of parentheses for grouping.\n";
     amhelpmessage += "Visit http://asciimath.org for a list of AsciiMath commands.\n\n";
     amhelpmessage += "You can also use LaTeX, with either slash-parentheses \\(...\\)\n";
     amhelpmessage += "or dollar signs $...$ as delimiters for inline math.";
     alert(amhelpmessage)
  });

  if(reading_questions_all_answered && uname != "guest" && role=="student") {
        make_submit_button();
  }
}
