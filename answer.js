

Storage.prototype.setObject = function(key, value) {
//    this.setItem(key, JSON.stringify(value));
    this.setItem(key, JSON.stringify(value, function(key, val) {
    return val.toFixed ? Number(val.toFixed(3)) : val;
}));
}

Storage.prototype.getObject = function(key) {
    var value = this.getItem(key);
    return value && JSON.parse(value);
}

console.log('22222222222222 222222222222222 222222222222');

var reading_questions = document.querySelectorAll("section.reading-questions article.exercise-like");

console.log('aaaaa reading_questions.length', reading_questions.length);
console.log('reading_questions 1', reading_questions[0]);
console.log('reading_questions 2', reading_questions[1]);


rq_answer_label = '<span'
rq_answer_label += ' class="readingquestion_make_answer addcontent';
rq_answer_label += ' ' + role + '"';
rq_answer_label += ' style="margin-left:1em; font-size:80%; color:#a0a;"';
rq_answer_label += '>';
if (role == "instructor") {
    rq_answer_label += 'Responses';
} else {
    rq_answer_label += 'Answer&rarr;';
}
rq_answer_label +='</span>';

for (var j=0; j < reading_questions.length; ++j) {
    var reading_question = reading_questions[j];
    var reading_question_id = reading_question.id;

    console.log("reading_question_id, last_child_type", reading_question_id, reading_question, "zzzz",reading_question.firstChild, "ggggg", reading_question.lastElementChild.tagName);
    rq_answer_id = reading_question_id + "_text";
    var existing_content = localStorage.getObject(rq_answer_id);
    console.log(rq_answer_id, "existing_rq_content", existing_content);

    if (reading_question.lastElementChild.tagName === "P") {
        console.log("ends in a p");
        reading_question.lastElementChild.innerHTML += rq_answer_label;
    } else {
       var this_answer_link = document.createElement('div');
       this_answer_link.innerHTML = rq_answer_label;
       reading_question.insertAdjacentElement("afterend", this_answer_link);
    }
    if (existing_content) {
       console.log("RQ_existing_content", reading_question_id, reading_question);
       console.log("those children", $('#'+reading_question_id).children(".readingquestion_make_answer"));
       $('#'+reading_question_id).find(".readingquestion_make_answer").addClass("hidecontrols");

       var this_rq_id_text = reading_question_id + "_text";
       var this_rq_id_controls = reading_question_id + "_controls";
       var answer_div = '<div';
       answer_div += ' id="' + this_rq_id_text + '"'
       answer_div += ' rows="' + '3' + '"';
       answer_div += ' style="width:100%; margin-top:0.5em;"';
       answer_div += '>';
       answer_div += existing_content;
       answer_div += '</div>';

/* need to save the original so that MathJax does not change it */
       var hidden_answer_div = '<div';
       hidden_answer_div += ' id="' + this_rq_id_text + '_hidden' + '"';
       hidden_answer_div += ' class="tex2jax_ignore" style="display: none">';
       hidden_answer_div += existing_content;
       hidden_answer_div += '</div>';


       var this_rq_controls = '<div id="' + this_rq_id_controls + '" class="input_controls hidecontrols" style="margin-bottom:-1.9em;">';
       this_rq_controls += '<span class="action clear_item rq_delete">delete</span><span class="action save_item rq_edit">edit</span>';
       this_rq_controls += '</div>'

       var this_rq_answer_and_controls = document.createElement('div');
       this_rq_answer_and_controls.setAttribute('style', 'width:80%; margin-left:auto; margin-right:auto; margin-top:0.5em;');
       this_rq_answer_and_controls.setAttribute('class', 'rq_answer');
       console.log("iiiii about to show the existing answer on #", reading_question_id);
       this_rq_answer_and_controls.innerHTML = hidden_answer_div + answer_div + this_rq_controls;
       $('#'+reading_question_id).append(this_rq_answer_and_controls);
     //  this.parentNode.insertAdjacentElement("afterend", this_rq_answer_and_controls);

    }

}
/* typeset the math in teh reading quesitons answers */
MathJax.Hub.Queue(["Typeset",MathJax.Hub]);

$('.readingquestion_make_answer').mousedown(function(e){
  console.log(".readingquestion_make_answer");
  $(this).addClass("hidecontrols");
//  var this_canvas_id = this.parentNode.nextSibling.id;
  var this_rq_id = this.parentNode.parentNode.id;
  var this_rq_id_text = this_rq_id + "_text";
  var this_rq_id_controls = this_rq_id + "_controls";
  console.log(".rq", this_rq_id);
  answer_textarea = '<textarea';
  answer_textarea += ' id="' + this_rq_id_text + '"'
  answer_textarea += ' rows="' + '3' + '"';
  answer_textarea += ' style="width:100%;"';
  answer_textarea += '>';
  answer_textarea += '</textarea>';

  var this_rq_controls = '<div id="' + this_rq_id_controls + '" class="input_controls" style="margin-bottom:-1.9em;">';
  this_rq_controls += '<span class="action clear_item rq_delete">delete</span> <span class="action save_item rq_save">save</span>';
  this_rq_controls += '</div>'

  var this_rq_answer_and_controls = document.createElement('div');
  this_rq_answer_and_controls.setAttribute('style', 'width:80%; margin-left:auto; margin-right:auto; margin-top:0.5em;');
//  this_rq_answer_and_controls.setAttribute('z-index', '2000');
  this_rq_answer_and_controls.innerHTML = answer_textarea + this_rq_controls;
  this.parentNode.insertAdjacentElement("afterend", this_rq_answer_and_controls);

  MathJax.Hub.Queue(["Typeset",MathJax.Hub]);

  var textarea = window.document.querySelector("textarea");
  textarea.addEventListener("keypress", function() {
     if(textarea.scrollTop != 0){
        textarea.style.height = textarea.scrollHeight + "px";
     }
  }, false);

});

// does not work because the content is dynamically loaded later
// $('.rq_save').mousedown(function(e){
$('body').on('click','.rq_save', function(){
  console.log(".rq_save");
//  var this_canvas_id = this.parentNode.nextSibling.id;
  var this_rq_id = this.parentNode.previousSibling.id;
  var this_rq_ans = this.parentNode.previousSibling;
  console.log(".rq_save", this_rq_id);
  console.log("this_rq_ans", this_rq_ans);
  var this_rq_text = this_rq_ans.value;
  this_rq_text = this_rq_text.trim();
  console.log("this_rq_text", this_rq_text);
  localStorage.setObject(this_rq_id, this_rq_text);

  document.getElementById(this_rq_id + "_hidden").innerHTML = this_rq_text;

  var this_ans_static = document.createElement('div');
  this_ans_static.setAttribute('id', this_rq_id);
  this_ans_static.setAttribute('style', "margin-top: 0.5em;");
  this_ans_static.innerHTML = this_rq_text
  this_rq_ans.replaceWith(this_ans_static);

  MathJax.Hub.Queue(["Typeset",MathJax.Hub]);

  $(this).parent().addClass("hidecontrols");

  $(this).parent().parent().addClass("rq_answer");

  var edit_button = document.createElement('span');
  edit_button.setAttribute('class', "action edit_item rq_edit");
  edit_button.innerHTML = "edit";
  this.replaceWith(edit_button);
});

$('body').on('click','.rq_edit', function(){
  console.log(".rq_edit");
//  var this_canvas_id = this.parentNode.nextSibling.id;
  var this_rq_id = this.parentNode.previousSibling.id;
  var this_rq_ans = this.parentNode.previousSibling;
  console.log(".rq_edit", this_rq_id);
  console.log("this_rq_ans", this_rq_ans);
  var this_rq_text = this_rq_ans.innerHTML;
  var this_rq_text_raw = document.getElementById(this_rq_id + "_hidden").innerHTML;
  console.log("this_rq_text", this_rq_text);
  console.log("this_rq_text raw", this_rq_text_raw);

   //this is copied from above.  need to eliminate repeated code

  var answer_textarea_editable = document.createElement('textarea');
  answer_textarea_editable.setAttribute('id', this_rq_id);
  answer_textarea_editable.setAttribute('rows', '3');
  answer_textarea_editable.setAttribute('style', 'width:100%;');

  this_rq_ans.replaceWith(answer_textarea_editable);
//  this_rq_ans.innerHTML = answer_textarea;
//  this_rq_ans.replaceWith(this_ans_static);

  $(this).parent().removeClass("hidecontrols");

  $(this).parent().parent().removeClass("rq_answer");

  var save_button = document.createElement('span');
  save_button.setAttribute('class', "action edit_item rq_save");
  save_button.innerHTML = "save";
  this.replaceWith(save_button);

  $('#' + this_rq_id).val(this_rq_text_raw);

  var textarea = window.document.querySelector("textarea");
  textarea.style.height = textarea.scrollHeight + "px";
  textarea.addEventListener("keypress", function() {
     if(textarea.scrollTop != 0){
        textarea.style.height = textarea.scrollHeight + "px";
     }
  }, false);
});

$('body').on('mouseover','.rq_answer', function(){
  console.log(".rq_answer");
  $(this).children().last().removeClass("hidecontrols");
  $(this).attr('z-index', '2000');
});
$('body').on('mouseleave','.rq_answer', function(){
  console.log(".rq_answer");
  $(this).children().last().addClass("hidecontrols");
  $(this).attr('z-index', '');
});

$('body').on('click','.rq_delete', function(){
  console.log(".rq_delete");
  var this_rq_id = this.parentNode.previousSibling.id;
  console.log(".rq_delete", this_rq_id);
  $(this).parent().parent().prev().children(".readingquestion_make_answer").removeClass("hidecontrols");
  $(this).parent().parent().remove();
  localStorage.removeItem(this_rq_id);

});


