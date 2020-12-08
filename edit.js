
/* preliminary hacks */


//$("p").tabIndex = 0;
// $("p").attr("tabindex", -1);
$(".autopermalink > a").attr("tabindex", -1);

$("#akX > *").attr("data-editable", 99);
var editable_objects = ["p", "ol", "ul", "li", "article"];
for(var j=0; j < editable_objects.length; ++j) {
    $(editable_objects[j]).attr("data-editable", 99);
    $(editable_objects[j]).attr("tabindex", -1);
}
// $("section > p").attr("data-editable", 99);
// $("section > article").attr("data-editable", 99);

/* the code */

console.log(" enabling edit");

user_level = "novice";

// we have to keep track of multiple consecutive carriage returns
this_char = "";
prev_char = "";
prev_prev_char = "";

// sometimes we have to prevent Tab from changing focus
this_focused_element = "";
prev_focused_element = "";
prev_prev_focused_element = "";
shift_active = false;

var result;

var menu_neutral_background = "#ddb";
var menu_active_background = "#fdd";

function randomstring(len=10) {
    return (Math.random() + 1).toString(36).substring(2,len)
}

/* need to distingiosh between th elist of objects of a type,
   and the list of types that can go in a location.
   OR, is it okay that these are all in one list?
   It seems to not be okay, because the "blockquote" entry
   says that only a "p" can go in a blockquote.  But blockquote
   is an entry  under "quoted".
*/
base_menu_for = {
"section": [["paragraph", "p"],
            ["list/table-like", "list-like"],
            ["definition-like", "definition-like"],
            ["theorem-like", "theorem-like"],
            ["remark-like"],
            ["example-like", "example-like"],
            ["image/video/sound", "display-like", "v"],
            ["math/chemistry/code", "math-like", "c"],
            ["project/exercise-like", "project-like", "j"],
            ["blockquote/poem/music/etc", "quoted"],
            ["aside-like", "aside-like", "d"],
            ["interactives"],
            ["layout-like"],
            ["section-like"]],
"blockquote": [["paragraph", "p"]],
"p": ["emphasis-like", "formula", "abbreviation", "symbols", ["ref or link", "ref"]]
}

inner_menu_for = {
"theorem-like": [["lemma"],
                 ["proposition"],
                 ["theorem"],
                 ["corollary"],
                 ["claim", "claim", "m"],
                 ["fact"],
                 ["identity"],
                 ["algorithm"]],
"definition-like": [["definition"],
                   ["axiom", "axiom"],
                   ["principle", "principle"],
                   ["heuristic",],
                   ["hypothesis", "hypothesis", "y"],
                   ["conjecture", "conjecture"]],
"list-like": [["ordered list", "ol"], ["unordered list", "ul"], ["dictionary list", "dl"], ["table"], ["table with caption", "tablecaption", "c"]],
"section-like": [["titled paragraph", "paragraphs"], ["reading questions", "rq"], ["exercises"], ["section"]],
"project-like": [["exercise"], ["activitiy"], ["investigation"], ["exploration", "exploration", "x"], ["project"]],
"remark-like": [["remark"], ["warning"], ["note"], ["observation"], ["convention"], ["insight"]],
"example-like": [["example"], ["question"], ["problem"]],
"display-like": [["image"], ["image with caption", "imagecaption", "m"], ["video"], ["video with caption", "videocaption", "d"], ["audio"]],
"aside-like": [["aside"], ["historical"], ["biographical"]],
"layout-like": [["side-by-side"], ["assemblage"], ["biographical aside"], ["titled paragraph", "paragraphs"]],
"math-like": [["math display", "mathdisplay"], ["chemistry display", "chemistrydisplay"], ["code listing", "code", "l"]],
"quoted": [["blockquote"], ["poem"], ["music"]],
"interactives": [["sage cell", "sagecell"], ["webwork"], ["asymptote"], ["musical score", "musicalscore"]],
"metadata": ["index entries", "notation"],
"emphasis-like": ["emphasis", ["foreign word", "foreign"], "book title", "article title", "inline quote", "name of a ship"],
// "abbreviation": ["ie", "eg", "etc", "et al"],  // i.e., etc., ellipsis, can just be typed.
"symbols": ["trademark", "copyright"],
"ref": ["ref to an internal id", "citation", "hyperlink"]
}

editing_container_for = { "p": 1,
 "theorem-like": ["theorem", "proposition", "lemma"],
 "lemma": 1 }

editing_tips = {
    "p": ["two RETurns to separate paragraphs",
          "three RETurns to end editing a paragraph",
          "TAB to insert emphasis, math, special characters, etc",
          "ESC to stop editing and save",
          "TAB to insert musical characters, species name, inline code, etc"]
}
          
function editing_tip_for(obj_type) {
    if (user_level != "novice") { return "" }
    if (obj_type in editing_tips) {
        possible_tips = editing_tips[obj_type];
        this_tip = possible_tips[Math.floor(Math.random()*possible_tips.length)];
    } else { this_tip = "" }
    return this_tip;
}

/*
var url = "https://github.com/oscarlevin/discrete-book/blob/master/ptx/sec_intro-intro.ptx";
console.log("first here");
fetch(url)
  .then(function(data) {
    // Here you get the data to modify as you please
    console.log("data", data)
    })
  .catch(function(error) {
    // If there is any error you will catch them here
    console.log("there was an error")
  });
console.log("then here");
*/

function standard_title_form(object_type) {
    var title_form = "<div><b>" + object_type + "&nbsp;NN</b>&nbsp;";
    title_form += '<input id="actively_editing_title" class="starting_point_for_editing" placeholder="Optional title" type="text"/>';
    title_form += '<input id="actively_editing_id" placeholder="Optional Id" class="input_id" type="text"/>';
    title_form += '</div>';

    return title_form
}

function menu_options_for(COMPONENT, level="inner") {
     var menu_for;
     if (level == "base") { menu_for = base_menu_for }
     else { menu_for = inner_menu_for }
     component = COMPONENT.toLowerCase();
     console.log("in menu_options_for", component);
     if (component in menu_for) {
         component_items = menu_for[component]
     } else {
         component_items = [["placeholder 1"], ["placeholder 2-like"], ["placeholder 3"], ["placeholder 4"], ["placeholder 5"]];
     }

//     this_menu = "<ol>";
     this_menu = "";
     for (var i=0; i < component_items.length; ++i) {
         this_item = component_items[i];

         this_item_name = this_item[0];
         this_item_label = this_item_name;
         this_item_shortcut = "";
         if (this_item.length == 3) {
             this_item_label = this_item[1];
             this_item_shortcut = this_item[2];
         } else if (this_item.length == 2) { 
             this_item_label = this_item[1];
         } 
      //      else if (this_item.length == 1) {
      //           this_item_label = this_item_name;
      //           this_item_shortcut = this_item_name.charAt(0)
      //       }

     //        this_item_name = this_item_name.replace(this_item_shortcut, '<b>' + this_item_shortcut + '</b>');

         this_menu += '<li tabindex="-1" data-env="' + this_item_label + '"';
         this_menu += ' data-env-parent="' + component + '"';
         if (this_item_shortcut) { 
             this_menu += ' data-jump="' + this_item_name.charAt(0) + ' ' + this_item_shortcut + '"';
             this_item_name = this_item_name.replace(this_item_shortcut, '<b>' + this_item_shortcut + '</b>');
         } else {
             this_menu += 'data-jump="' + this_item_name.charAt(0) + '"';
         }
         if(i==0) { this_menu += ' id="choose_current"'}
         this_menu += '>';

         first_character = this_item_name.charAt(0);
         this_item_name = this_item_name.replace(first_character, "<b>" + first_character + "</b>");

         this_menu += this_item_name 
                 // little right triangle if there is a submenu
         if (this_item_label in inner_menu_for) { this_menu += '<div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div>' }
         this_menu += '</li>';
         
     }
//     this_menu += "</ol>";

     return this_menu
}

function top_menu_options_for(this_obj) {
    console.log("top_menu_options_for", this_obj);
    var this_object_type = this_obj.tagName;   //  needs to examine other attributes and then look up a reasonable name
    var this_list = '<li tabindex="-1" id="choose_current" data-env="p" data-action="edit">Edit ' + this_object_type + '</li>';
    this_list += '<li tabindex="-1" data-env="' + this_object_type + '" data-location="enter">Enter ' + this_object_type + '</li>';
    this_list += '<li tabindex="-1" data-env="' + this_object_type + '" data-location="before">Insert before<div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div></li>';
    this_list += '<li tabindex="-1" data-env="' + this_object_type + '" data-location="after">Insert after<div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div></li>';
    this_list += '<li tabindex="-1" data-env="' + this_object_type + '">Metadata<div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div></li>';
    this_list += '<li tabindex="-1" data-env="' + this_object_type + '">Move or delete<div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div></li>';
    return this_list
}

function edit_menu_for(this_obj_id, motion="entering") {
    console.log("make edit menu", motion, "for", this_obj_id);

    if (motion == "entering") { menu_location = "afterbegin" }
    else { menu_location = "afterend" }  // when motion is 'leaving'

    var edit_menu_holder = document.createElement('div');
//    edit_menu_holder.setAttribute('class', 'edit_menu_holder');
    edit_menu_holder.setAttribute('id', 'edit_menu_holder');
    edit_menu_holder.setAttribute('tabindex', '-1');
    console.log("adding menu for", this_obj_id);
    document.getElementById(this_obj_id).insertAdjacentElement(menu_location, edit_menu_holder);

    var edit_option = document.createElement('span');
    edit_option.setAttribute('id', 'enter_choice');

    if (motion == "entering") {
        edit_option.setAttribute('data-location', 'next');
        edit_option.innerHTML = "edit near here?";
    } else {
        edit_option.setAttribute('data-location', 'stay');
        edit_option.innerHTML = "continue editing [this object]";
    }
    document.getElementById("edit_menu_holder").insertAdjacentElement("afterbegin", edit_option);
}

function local_menu_for(this_obj_id) { 
    console.log("make local edit menu for", this_obj_id);
    var local_menu_holder = document.createElement('div');
    local_menu_holder.setAttribute('id', 'local_menu_holder');
    local_menu_holder.setAttribute('tabindex', '-1');
    console.log("adding local menu for", this_obj_id);
    document.getElementById(this_obj_id).insertAdjacentElement("beforebegin", local_menu_holder);
    
    var enter_option = document.createElement('ol');
    enter_option.setAttribute('id', 'edit_menu');
    
    enter_option.innerHTML = menu_options_for("p", "base");

    document.getElementById("local_menu_holder").insertAdjacentElement("afterbegin", enter_option);
   // prev_focused_element.focus();
    // next_menu_item.focus();
}

/*
let response = await fetch(url);
console.log("status of response",response.status);
*/

function container_for_editing(obj_type) {
    // the most recent characters were TAB and RET from navigatin gthe menu, which are irrelevant now.
    prev_char = "";
    prev_prev_char = "";
    var this_content_container = document.createElement('div');
    this_content_container.setAttribute('id', "actively_editing");

    if (obj_type == "p") {
        this_content_container.setAttribute('data-objecttype', 'p');
        var obj_type_name = "paragraph";
        this_tip = editing_tip_for(obj_type);
        if (this_tip) {
            instructions = '<span class="group_description">' + 'Tip: ' + this_tip + '</span>';
        } else { instructions = '' }
        var editingregion_container_start = '<div class="editing_p_holder">';
        var editingregion_container_end = '</div>';
   //     var editingregion = '<textarea id="actively_editing_p" class="starting_point_for_editing" style="width:100%;" placeholder="' + obj_type_name + '"></textarea>';
        var editingregion = '<textarea class="editing_p starting_point_for_editing" style="width:100%;" placeholder="' + obj_type_name + '"></textarea>';
        this_content_container.innerHTML = instructions + editingregion_container_start + editingregion + editingregion_container_end;
    } else if ( editing_container_for["theorem-like"].includes(obj_type) ) {
        console.log("making a form for", obj_type);
        this_content_container.setAttribute('data-objecttype', 'theorem-like');
        var title = standard_title_form(obj_type);
/*
        var title = "<div><b>" + obj_type + "&nbsp;NN</b>&nbsp;";
        title += '<input id="actively_editing_title" class="starting_point_for_editing" placeholder="Optional title" type="text"/>';
        title += '<input id="actively_editing_id" placeholder="Optional Id" class="input_id" type="text"/>';
        title += '</div>';
*/
        var statement_container_start = '<div class="editing_statement">';
        var statement_container_end = '</div>';
        var editingregion_container_start = '<div class="editing_p_holder">'
        var editingregion_container_end = '</div>'
        var statementinstructions = '<span class="group_description">statement (paragraphs, images, lists, etc)</span>';
        var statementeditingregion = '<textarea id="actively_editing_statement" style="width:100%;" placeholder="first paragraph of statement"></textarea>';
        var statement = statement_container_start + editingregion_container_start;
        statement += statementinstructions;
        statement += statementeditingregion;
        statement += editingregion_container_end + statement_container_end;

        var proof_container_start = '<div class="editing_proof">';
        var proof_container_end = '</div>';
        var proofinstructions = '<span class="group_description">optional proof (paragraphs, images, lists, etc)</span>';
        var proofeditingregion = '<textarea id="actively_editing_proof" style="width:100%;" placeholder="first paragraph of optional proof"></textarea>';
 
        var proof = proof_container_start + editingregion_container_start;
        proof += proofinstructions;
        proof += proofeditingregion;
        proof += editingregion_container_end + proof_container_end;

        this_content_container.innerHTML = title + statement + proof
    }

    return this_content_container
}

function hack_to_fix_first_textbox_character(thisID) {
//    this_text = $("#" + thisID).val();
//    console.log("this edit box" + this_text + "was");
//    this_text = this_text.replace(/^\s/,"");
//    this_text = this_text.replace(/^\s/,"");
//    console.log("this edit box" + this_text + "is");
//    $("#" + thisID).val(this_text);
}

function edit_in_place(obj) {
    thisID = obj.getAttribute("id");
    console.log("will edit in place", thisID);
// this only works for paragraphs, so go back and allow editing of other types
    if( internalSource[thisID] ) {
      if(obj.tagName == "P") {
        var this_content_container = document.createElement('div');
        this_content_container.setAttribute('id', "actively_editing");
        $("#" + thisID).replaceWith(this_content_container);

        var idOfEditContainer = thisID + '_input';
   //     var idOfEditText = thisID + '_input_text';
        var idOfEditText = 'editing' + '_input_text';
        var textarea_editable = document.createElement('textarea');
        textarea_editable.setAttribute('class', 'text_source');
        textarea_editable.setAttribute('id', idOfEditText);
        textarea_editable.setAttribute('data-source_id', thisID);
        textarea_editable.setAttribute('data-parent_id', internalSource[thisID]["parent"][0]);
        textarea_editable.setAttribute('data-parent_component', internalSource[thisID]["parent"][1]);
        textarea_editable.setAttribute('style', 'width:99%;');

  //      document.getElementById(idOfEditContainer).insertAdjacentElement("afterbegin", textarea_editable);
        document.getElementById('actively_editing').insertAdjacentElement("afterbegin", textarea_editable);

  //      id_of_existing_content = internalSource[thisID]["content"];
        $('#' + idOfEditText).val(internalSource[thisID]["content"]);
 //       $('#' + idOfEditText).val(internalSource[id_of_existing_content]);
        document.getElementById(idOfEditText).focus();
        document.getElementById(idOfEditText).setSelectionRange(0,0);
        textarea_editable.style.height = textarea_editable.scrollHeight + "px";
        console.log("made edit box for", thisID);
        textarea_editable.addEventListener("keypress", function() {
          textarea_editable.style.height = textarea_editable.scrollHeight + "px";
       });
      } else {
        console.log("Error: I don;t know how to edit_in_place", obj)
      }
    } else {
        console.log("Error: edit_in_place of object that is not already known", obj);
        console.log("What is known:", internalSource)
    }
}

var OldinternalSource = {  // currently the key is the HTML id
   "cak": {"xml:id": "", "permid": "cak", "ptxtag": "p", "title": "", 
           "content": '13579'},
   "UvL": {"xml:id": "", "permid": "UvL", "ptxtag": "p", "title": "", 
           "content": '246810'},
   "246810": '    Defining <em>discrete mathematics</em>\n    is hard because defining <em>mathematics</em> is hard.\n    What is mathematics?\n    The study of numbers?\n In part, but you also study functions and lines and triangles and parallelepipeds and vectors and\n <ellipsis/>.\n Or perhaps you want to say that mathematics is a collection of tools that allow you to solve problems.\n What sort of problems?\n Okay, those that involve numbers,\n functions, lines, triangles,\n <ellipsis/>.\n Whatever your conception of what mathematics is,\n try applying the concept of <q>discrete</q> to it, as defined above.\n Some math fundamentally deals with <em>stuff</em>\n that is individually separate and distinct.',
   "13579": '<&>357911<;>: separate - detached - distinct - abstract.',
   "357911": {"xml:id": "", "permid": "", "ptxtag": "em", "title": "", 
           "content": '124567'},
   "124567": "Synonyms"
}

var internalSource = {  // currently the key is the HTML id
   "hPw": {"xml:id": "", "permid": "hPw", "ptxtag": "section", "title": "What is Discrete Mathematics?",
           "content": "<&>akX<;>\n<&>UvL<;>\n<&>ACU<;>\n<&>gKd<;>\n<&>MRm<;>\n<&>udO<;>\n<&>sYv<;>\n<&>ZfE<;>"},
   "cak": {"xml:id": "", "permid": "cak", "ptxtag": "p", "title": "", "parent": ["akX","content"],
           "content": "<&>357911<;>: separate - detached - distinct - abstract."},
   "akX": {"xml:id": "", "permid": "akX", "ptxtag": "blockquote", "title": "", "parent": ["hPw","content"],
           "content": "<&>357911<;>\n<&>PLS<;>\n<&>vTb<;>\n<&>cak<;>"},
   "UvL": {"xml:id": "", "permid": "UvL", "ptxtag": "p", "title": "","parent": ["hPw","content"],
           "content": "    Defining <em>discrete mathematics</em>\n    is hard because defining <em>mathematics</em> is hard.\n    What is mathematics?\n    The study of numbers?\n In part, but you also study functions and lines and triangles and parallelepipeds and vectors and\n <ellipsis/>.\n Or perhaps you want to say that mathematics is a collection of tools that allow you to solve problems.\n What sort of problems?\n Okay, those that involve numbers,\n functions, lines, triangles,\n <ellipsis/>.\n Whatever your conception of what mathematics is,\n try applying the concept of <q>discrete</q> to it, as defined above.\n Some math fundamentally deals with <em>stuff</em>\n that is individually separate and distinct."},
//           "content": '246810'},
//   "246810": '    Defining <em>discrete mathematics</em>\n    is hard because defining <em>mathematics</em> is hard.\n    What is mathematics?\n    The study of numbers?\n In part, but you also study functions and lines and triangles and parallelepipeds and vectors and\n <ellipsis/>.\n Or perhaps you want to say that mathematics is a collection of tools that allow you to solve problems.\n What sort of problems?\n Okay, those that involve numbers,\n functions, lines, triangles,\n <ellipsis/>.\n Whatever your conception of what mathematics is,\n try applying the concept of <q>discrete</q> to it, as defined above.\n Some math fundamentally deals with <em>stuff</em>\n that is individually separate and distinct.',
//   "13579": '<&>357911<;>: separate - detached - distinct - abstract.',
   "357911": {"xml:id": "", "permid": "", "ptxtag": "em", "title": "",
           "content": 'Synonyms'},
   "sYv": {"xml:id": "", "permid": "sYv", "ptxtag": "p", "parent": ["hPw","content"],
           "content": "One way to get a feel for the subject is to consider the types of problems you solve in discrete math. Here are a few simple examples:"}
//           "content": '124567'},
//   "124567": "Synonyms"
}



function local_menu_navigator(e) {
    e.preventDefault();
    if (e.code == "Tab") {
        if (!document.getElementById('local_menu_holder')) {  // no local menu, so make one
            local_menu_for('actively_editing');
//            local_menu_for('actively_editing_p');
//  ???  local_menu_for('editing' + '_input_text');
        }  else {  //Tab must be cycling through a menu
            // this is copied from main_menu_navigator, so maybe consolidate
            current_active_menu_item = document.getElementById('choose_current');
            next_menu_item = current_active_menu_item.nextSibling;
            console.log("current_active_menu_item", current_active_menu_item, "next_menu_item", next_menu_item);
            if (!next_menu_item) { next_menu_item = current_active_menu_item.parentNode.firstChild }
            console.log("current_active_menu_item", current_active_menu_item, "next_menu_item", next_menu_item);
            current_active_menu_item.removeAttribute("id");
            console.log("current_active_menu_item", current_active_menu_item, "next_menu_item", next_menu_item);
//        current_active_menu_item.setAttribute("class", "chosen");
            next_menu_item.setAttribute("id", "choose_current");
            console.log("setting focus on",next_menu_item);
            next_menu_item.focus();
        }
    } else {
        main_menu_navigator(e)
    }
}

function ptx_to_html(input_text) {
    output_text = input_text;

    output_text = output_text.replace(/<term>/g, "<b>"); 
    output_text = output_text.replace(/<\/term>/g, "</b>"); 
    return(output_text)
}
function hide_new_source(ptx_src, src_type) {
    if (!ptx_src) { return }
    var hidden_div = document.createElement('div');
    hidden_div.setAttribute("id", "in_progress_" + src_type);
    hidden_div.setAttribute("style", "display: none");
    hidden_div.innerHTML = ptx_src;
    document.body.insertAdjacentElement('beforeend', hidden_div);
}
function save_new(objecttype) {
    // placeholder
}
function display_new(objectclass, objecttype, whereat, relativelocation="beforebegin") {
    if (objectclass == "theorem-like") {
        object_in_html = document.createElement("article");
        object_in_html.setAttribute("class", objectclass + " " + objecttype);
        object_in_html.setAttribute("tabindex", -1);
        object_in_html.setAttribute("data-editable", 99);

        object_title = document.getElementById('actively_editing_title').value;
        object_id = document.getElementById('actively_editing_id').value;
        object_id = object_id || randomstring();

        if (object_id) { object_in_html.setAttribute("id", object_id); }

        object_heading_html = '<h6 class="heading">';
        object_heading_html += '<span class="type">' + objecttype + '</span>';
        object_heading_html += '<span class="space">' + " " + '</span>';
        object_heading_html += '<span class="codenumber">' + "NN" + '</span>';

        if (object_title) {
            object_heading_html += '<span class="space">' + " " + '</span>';
            object_heading_html += '<span class="creator">(' + object_title + ')</span>';
        }
        object_heading_html += '<span class="period">' + "." + '</span>';
        object_heading_html += '</h6>';

        object_statement_ptx = document.getElementById("in_progress_statement").innerHTML;
        document.getElementById("in_progress_statement").remove();
        object_statement_html = object_statement_ptx;   // add the transform later

        object_in_html.innerHTML = object_heading_html + object_statement_html;

        whereat.insertAdjacentElement(relativelocation, object_in_html);
        console.log("trying to put the focus on",object_in_html);
        object_in_html.focus();

        if(object_proof = document.getElementById("in_progress_proof")) { //if there is a proof
            object_proof_ptx = object_proof.innerHTML;
            object_proof.remove;
            proof_in_html = document.createElement("article");
            proof_in_html.setAttribute("class", "hiddenproof");
            proof_in_html.innerHTML = '<a data-knowl="" class="id-ref proof-knowl original" data-refid="hk-Jkl"><h6 class="heading"><span class="type">Proof<span class="period">.</span></span></h6></a>';
            
            document.activeElement.insertAdjacentElement("afterend", proof_in_html)
         }

    } else {
        alert("I don;t know how to display", objectclass)
    }
}

function assemble_internal_version_changes() {
    console.log("current active element to be saved", document.activeElement);

    var possibly_changed_ids = [];
    var nature_of_the_change = "";

    var object_being_edited = document.activeElement;
    var location_of_change = object_being_edited.parentElement;

    if (object_being_edited.tagName == "TEXTAREA") {
        nature_of_the_chnage = "replace";
        var textbox_being_edited = object_being_edited;  //document.getElementById('actively_editing_p');
        var paragraph_content = textbox_being_edited.value;
        paragraph_content = paragraph_content.trim();

        var cursor_location = textbox_being_edited.selectionStart;

        console.log("cursor_location", cursor_location, "out of", paragraph_content.length, "paragraph_content", paragraph_content);

        // does the textbox contain more than one paragraph?
        var paragraph_content_list = paragraph_content.split("\n\n");
        var num_paragraphs = paragraph_content_list.length;

        var parent_and_location = [object_being_edited.getAttribute("data-parent_id"), object_being_edited.getAttribute("data-parent_component")];
        var this_arrangement_of_objects = "";
        console.log("parent_and_location", parent_and_location);
        for(var j=0; j < num_paragraphs; ++j) {
            if (!paragraph_content_list[j] ) { continue }
            if (j == 0 && (prev_id = textbox_being_edited.getAttribute("data-source_id"))) {
                if (prev_id in internalSource) {
                    // the content is referenced, so we update the referenced content
               //     id_of_content = internalSource[prev_id]["content"];
               //     internalSource[id_of_content] = paragraph_content_list[j]
                    internalSource[prev_id]["content"] = paragraph_content_list[j];  // should we write [0] ?
                    possibly_changed_ids.push(prev_id);
                    this_arrangement_of_objects = internalSource[parent_and_location[0]][parent_and_location[1]];
                } else {
                    console.log("error:  existing tag from input", prev_id, "not in internalSource")
                }
            } else {  // a newly created paragraph
                var this_object_internal = {"ptxtag": "p", "title": ""}; //p don't have title
                this_object_label = randomstring();
         //       this_content_label = randomstring();
                this_object_internal["xmlid"] = this_object_label;
                this_object_internal["permid"] = "";
                this_object_internal["parent"] = parent_and_location;
                console.log("need to add paragraph",this_object_label, "inside", this_arrangement_of_objects, "after (or after after)", prev_id);
 //   the_ans = the_ans.replace(/(^|\s|-)\$([^\$\f\r\n]+)\$(\s|\.|,|;|:|\?|!|-|$)/g, "$1\\($2\\)$3");

                var object_before = new RegExp('(<&>' + prev_id + '<;>)');
                this_arrangement_of_objects = this_arrangement_of_objects.replace(object_before, '$1' + '\n<&>' + this_object_label + '<;>');
                prev_id = this_object_label;
                
         //       this_object_internal["content"] = this_content_label;
                this_object_internal["content"] = paragraph_content_list[j];
                internalSource[this_object_label] = this_object_internal
                possibly_changed_ids.push(this_object_label);
          //      internalSource[this_content_label] = paragraph_content_list[j];
            }
        }
        console.log("this_arrangement_of_objects was",  internalSource[parent_and_location[0]][parent_and_location[1]]);
        internalSource[parent_and_location[0]][parent_and_location[1]] = this_arrangement_of_objects;
        console.log("this_arrangement_of_objects is", this_arrangement_of_objects);
    } else {
        alert("don;t know how to assemble_internal_version_changes of", object_being_edited.tagName)
    }
    console.log("finished assembling internal version, which is now:",internalSource);
    return [nature_of_the_change, location_of_change, possibly_changed_ids]
}
            
function html_from_internal_id(the_id) {
    var the_object = internalSource[the_id];
    var ptxtag = the_object["ptxtag"];

    if (ptxtag == "p") {
        html_of_this_object = document.createElement('p');
        html_of_this_object.setAttribute("data-editable", 99);
        html_of_this_object.setAttribute("tabindex", -1);
        html_of_this_object.setAttribute("id", the_id);

        var content_id = the_object["content"];
        html_of_this_object.innerHTML = internalSource[content_id];
    } else {
         alert("don't know how to make html from", the_object)
    }
    return html_of_this_object
}

function assemble_html_changes(ids_that_changed) {

/// copied, in progress
        var holder_of_object_being_edited = object_being_edited.parentElement.parentElement;
        for(var j=0; j < num_paragraphs; ++j) {
            if (!paragraph_content_list[j] ) { continue }
            new_ptx_source += "<p>" + "\n";
            new_ptx_source += paragraph_content_list[j];
            new_ptx_source += "\n" + "</p>" + "\n";
            var object_as_html = document.createElement('p');
            object_as_html.setAttribute("data-editable", 99);
            object_as_html.setAttribute("tabindex", -1);
            object_as_html.setAttribute("id", randomstring());
     //       object_as_html.setAttribute("class", "just_added");
            object_as_html.innerHTML = ptx_to_html(paragraph_content_list[j]);
     //       document.getElementById('actively_editing').insertAdjacentElement('beforebegin', object_as_html);
            holder_of_object_being_edited.insertAdjacentElement('beforebegin', object_as_html);
        } 
        
    
        console.log("finished editing a paragraph", new_ptx_source, "previous is new_ptx_source");
    
        console.log("current item of focus", document.activeElement);
        console.log("its parent", document.activeElement.parentElement);
        if (holder_of_object_being_edited.id == "actively_editing") { // we are only editing a p
            console.log("will focus on what we just added",$(holder_of_object_being_edited).prev('[data-editable="99"]'));
            $(holder_of_object_being_edited).prev('[data-editable="99"]').focus();
            console.log("next item of focus", document.activeElement);
//    document.getElementById('actively_editing').remove();
            $(":focus").addClass("may_select");
            edit_menu_for($(":focus").attr("id"), "entering");
        } else if (holder_of_object_being_edited.classList.contains("editing_statement")) {
        // hide the ptx_source to be retrieved later
            hide_new_source(new_ptx_source, "statement");
              // the p is in a statement (of theorem-like or definition-like or remark-like or ...)
            if (holder_of_object_being_edited.parentElement.getAttribute('data-objecttype') == "theorem-like") {
              // now focus switches to the proof?
                console.log("focus shoudl switch to",holder_of_object_being_edited.nextSibling.firstChild.children[1]);
                holder_of_object_being_edited.nextSibling.firstChild.children[1].focus()  // 1 to skip the Tip
            } else {
                alert("don't know where to go next");
               // I guess we are done editing this object?
            }
        } else if (holder_of_object_being_edited.classList.contains("editing_proof")) {
            hide_new_source(new_ptx_source, "proof");
            // done editing the theorem-like, to put focus on the next thing and display/save the theorem
            save_new("theorem");
            display_new("theorem-like", "corollary", document.getElementById("actively_editing"), "afterend");
            console.log("is focus on the new object?", $(":focus"));
            $(":focus").addClass("may_select");
            edit_menu_for($(":focus").attr("id"), "entering");
            document.getElementById("actively_editing").remove();
            console.log("just did display_new");
        } else { // this p is in a larvger object, like a theorem or li
            
            alert("inside an object, don; tknow what to do next")
        }
        console.log("holder_of_object_being_edited.remove()", holder_of_object_being_edited);
  //      document.getElementById("actively_editing").remove();
            holder_of_object_being_edited.remove();
/*
    } else {
        console.log("trouble saving", object_being_edited);
        alert("don;t know how to save ", object_being_edited.tagName)
    }
*/
}

function update_ptx_identifiers() {
}

function save_ptx_version() {
}


function insert_html_version() {
}

function update_navigation() {
}

function save_current_editing() {
    console.log("current active element to be saved", document.activeElement);
    //not currently used
 //   var object_being_edited = document.getElementById('actively_editing');
    var object_being_edited = document.activeElement;

    var new_ptx_source = "";

    if (object_being_edited.tagName == "TEXTAREA") {
        var textbox_being_edited = object_being_edited;  //document.getElementById('actively_editing_p');
        var paragraph_content = textbox_being_edited.value;
        paragraph_content = paragraph_content.trim();

        var cursor_location = textbox_being_edited.selectionStart;

        console.log("cursor_location", cursor_location, "out of", paragraph_content.length, "paragraph_content", paragraph_content);
        var paragraph_content_list = paragraph_content.split("\n\n");

        var holder_of_object_being_edited = object_being_edited.parentElement.parentElement;
        for(var j=0; j < paragraph_content_list.length; ++j) {
            if (!paragraph_content_list[j] ) { continue }
            new_ptx_source += "<p>" + "\n";
            new_ptx_source += paragraph_content_list[j];
            new_ptx_source += "\n" + "</p>" + "\n";
            var object_as_html = document.createElement('p');
            object_as_html.setAttribute("data-editable", 99);
            object_as_html.setAttribute("tabindex", -1);
            object_as_html.setAttribute("id", randomstring());
     //       object_as_html.setAttribute("class", "just_added");
            object_as_html.innerHTML = ptx_to_html(paragraph_content_list[j]);
     //       document.getElementById('actively_editing').insertAdjacentElement('beforebegin', object_as_html);
            holder_of_object_being_edited.insertAdjacentElement('beforebegin', object_as_html);
        } 
        
    
        console.log("finished editing a paragraph", new_ptx_source, "previous is new_ptx_source");
    
        console.log("current item of focus", document.activeElement);
        console.log("its parent", document.activeElement.parentElement);
        if (holder_of_object_being_edited.id == "actively_editing") { // we are only editing a p
            console.log("will focus on what we just added",$(holder_of_object_being_edited).prev('[data-editable="99"]'));
            $(holder_of_object_being_edited).prev('[data-editable="99"]').focus();
            console.log("next item of focus", document.activeElement);
//    document.getElementById('actively_editing').remove();
            $(":focus").addClass("may_select");
            edit_menu_for($(":focus").attr("id"), "entering");
        } else if (holder_of_object_being_edited.classList.contains("editing_statement")) {
        // hide the ptx_source to be retrieved later
            hide_new_source(new_ptx_source, "statement");
              // the p is in a statement (of theorem-like or definition-like or remark-like or ...)
            if (holder_of_object_being_edited.parentElement.getAttribute('data-objecttype') == "theorem-like") {
              // now focus switches to the proof?
                console.log("focus shoudl switch to",holder_of_object_being_edited.nextSibling.firstChild.children[1]);
                holder_of_object_being_edited.nextSibling.firstChild.children[1].focus()  // 1 to skip the Tip
            } else {
                alert("don't know where to go next");
               // I guess we are done editing this object?
            }
        } else if (holder_of_object_being_edited.classList.contains("editing_proof")) {
            hide_new_source(new_ptx_source, "proof");
            // done editing the theorem-like, to put focus on the next thing and display/save the theorem
            save_new("theorem");
            display_new("theorem-like", "corollary", document.getElementById("actively_editing"), "afterend");
            console.log("is focus on the new object?", $(":focus"));
            $(":focus").addClass("may_select");
            edit_menu_for($(":focus").attr("id"), "entering");
            document.getElementById("actively_editing").remove();
            console.log("just did display_new");
        } else { // this p is in a larvger object, like a theorem or li
            
            alert("inside an object, don; tknow what to do next")
        }
        console.log("holder_of_object_being_edited.remove()", holder_of_object_being_edited);
  //      document.getElementById("actively_editing").remove();
            holder_of_object_being_edited.remove();
    } else {
        console.log("trouble saving", object_being_edited);
        alert("don;t know how to save ", object_being_edited.tagName)
    }

    console.log("internalSource", internalSource)
}

function local_editing_action(e) {
    console.log("in local_editing_action for" ,e.code);
    if (e.code == "Escape") {
        console.log("putting focus back");
        prev_focused_element.focus();
    } else if (e.code == "Tab") {
        e.preventDefault();
        console.log("making a local menu");
        local_menu_navigator(e);
    } else if (e.code == "Escape") {
            e.preventDefault();
            assemble_internal_version_changes();
            save_current_editing()
    } else if (e.code == "Enter") {
        console.log("saw a Ret");
    //    e.preventDefault();
        if (prev_char.code == "Enter" && prev_prev_char.code == "Enter") {
            console.log("need to save");
            e.preventDefault();
            assemble_internal_version_changes();
            save_current_editing()
        }
    } else {
        console.log("e.code was not one of those we were looking for", e)
    }
}

function main_menu_navigator(e) {  // we are not currently editing
                              // so we are building the menu for the user to decide what/how to edit

 // too early   e.preventDefault();  // we are navigating a menu, we we control what keystrokes mean
  //  if ((e.code == "Tab" || e.code == "ArrowDown") && prev_char.code != "ShiftLeft") {
    if ((e.code == "Tab" || e.code == "ArrowDown") && !e.shiftKey) {
       e.preventDefault();
       console.log("hit a Tab (or ArrowDown");
       console.log("prev_char", prev_char.code, "xxxx", prev_char);
       console.log("focus is on", $(":focus"));

       // we are tabbing along deciding what component to edit
       // so a Tab means to move on
       // so remove the option to edit one object
       if(this_choice = document.getElementById('enter_choice')) {
           console.log("there already is an 'enter_choice'");
           // there are two cases:  1) we are at the top of a block (and so may enter it or add near it, or move on)
           //                       2) we are at the bottom (actually, after) a block, and may return to it, or move on
           var this_menu = document.getElementById("edit_menu_holder");
           if (this_choice.getAttribute('data-location') == 'next') {

               $(this_menu).parent().removeClass("may_select");
               console.log("item to get next focus",$("#edit_menu_holder").parent().next('[data-editable="99"]'), "which has length", $("#edit_menu_holder").parent().next('[data-editable="99"]').length);
     //////          if(!$(this_menu).parent().next('[data-editable="99"]').length) { //at the end of a block, so new menu goes at end
               if(!$(this_menu).parent().next().length) { //at the end of a block, so new menu goes at end
               //    e.preventDefault();
                   var enclosing_block = $(this_menu).parent().parent()[0];
                   console.log("at the end of", enclosing_block, "with id", enclosing_block.id);
                   this_menu.remove();
                   edit_menu_for(enclosing_block.getAttribute("id"), "leaving");
                   console.log("focus is on",  $(":focus"));
                   enclosing_block.classList.add("may_leave");
               //    document.getElementById('choose_current').focus();
                   document.getElementById('enter_choice').focus();
                   console.log("document.getElementById('enter_choice')", document.getElementById('enter_choice'), $(":focus"));
                   return
                }
                else {
                   console.log("moving to next *editable* object A");
    /////////               $(this_menu).parent().next('[data-editable="99"]').focus();
                   $(this_menu).parent().nextAll('[data-editable="99"]')[0].focus();
                   this_menu.remove()
               }
           } else if (this_choice.getAttribute('data-location') == 'stay') { // at end of block, and want to move on
               // remove class from prev sibling, find its next sibling
               console.log("about to leave a block");
               console.log("this_menu", this_menu, "this_menu.previousSibling", document.getElementById('edit_menu_holder').previousSibling);
           //    block_we_are_leaving = document.getElementById('edit_menu_holder').previousSibling;
               console.log("again:  this_menu", this_menu, "this_menu.previousSibling", this_menu.previousSibling);
               console.log("are they the sme?", document.getElementById('edit_menu_holder') == this_menu, document.getElementById('edit_menu_holder'), this_menu);
               block_we_are_leaving = this_menu.previousSibling;
               block_we_are_leaving.classList.remove("may_leave");
               console.log("$(block_we_are_leaving)",$(block_we_are_leaving), "xxxx", $(block_we_are_leaving).next(), "yyyyy", $(block_we_are_leaving).next('[data-editable="99"]'));
               console.log("moving to next object B");
               next_block_to_edit = $(this_menu).next('[data-editable="99"]');
               this_menu.remove()
               $(next_block_to_edit).focus();
       //        $(block_we_are_leaving).next('[data-editable="99"]').focus();
               console.log("left a block.  focus is now on", $(":focus"));
           }  else { alert("Error:  enter_choice without data-location") }
       }
       // and add the option to edit the next object
       if (!document.getElementById('edit_menu_holder')) {  // we are not already navigating a menu
    //       e.preventDefault();
           edit_menu_for(document.activeElement.id);        // so create one
           $(":focus").addClass("may_select");
           console.log("element with fcous is", $(":focus"));
           console.log("putting focus on", document.getElementById('edit_menu_holder'));
           document.getElementById('edit_menu_holder').focus();
           console.log("element with fcous is", $(":focus"));
           console.log("are we done tabbing to the next item?");
       } else {
        current_active_menu_item = document.getElementById('choose_current');
        next_menu_item = current_active_menu_item.nextSibling;
        console.log("current_active_menu_item", current_active_menu_item, "next_menu_item", next_menu_item);
        if (!next_menu_item) { next_menu_item = current_active_menu_item.parentNode.firstChild }
        console.log("current_active_menu_item", current_active_menu_item, "next_menu_item", next_menu_item);
        current_active_menu_item.removeAttribute("id");
        console.log("current_active_menu_item", current_active_menu_item, "next_menu_item", next_menu_item);
//        current_active_menu_item.setAttribute("class", "chosen");
        next_menu_item.setAttribute("id", "choose_current");
        console.log("setting focus on",next_menu_item);
        next_menu_item.focus();
      }

//    } else if (e.code == "Tab" && prev_char.code == "ShiftLeft") {  // Shift-Tab to prevous object
    } else if ((e.code == "Tab" && e.shiftKey) || e.code == "ArrowUp") {  // Shift-Tab to prevous object
     // recopied code:  consolidate
        if(this_choice = document.getElementById('enter_choice')) {
           console.log("there already is an 'enter_choice'");
           // there are two cases:  1) we are at the top of a block (and so may enter it or add near it, or move on)
           //                       2) we are at the bottom (actually, after) a block, and may return to it, or move on
           var this_menu = document.getElementById("edit_menu_holder");
           if (this_choice.getAttribute('data-location') == 'next') {  // we are at the top of a block
               
               $(this_menu).parent().removeClass("may_select");
               console.log("item to get next focus",$("#edit_menu_holder").parent().prev('[data-editable="99"]'), "which has length", $("#edit_menu_holder").parent().next('[data-editable="99"]').length);
    ////////           if(!$(this_menu).parent().prev('[data-editable="99"]').length) { //at the start of a block, so go up one
               if(!$(this_menu).parent().prev().length) { //at the start of a block, so go up one
               //    e.preventDefault(); 
                   var enclosing_block = $(this_menu).parent().parent()[0]; 
                   console.log("at the end of", enclosing_block, "with id", enclosing_block.id);
                   this_menu.remove();
                   edit_menu_for(enclosing_block.getAttribute("id"), "entering");
                   console.log("focus is on",  $(":focus"));
                   enclosing_block.classList.add("may_select");
               //    document.getElementById('choose_current').focus();
                   document.getElementById('enter_choice').focus();
                   console.log("document.getElementById('enter_choice')", document.getElementById('enter_choice'), $(":focus"));
                   return
                }
                else {
                   console.log("moving to next object C");
     /////////              $(this_menu).parent().prev('[data-editable="99"]').focus();
                   $(this_menu).parent().prevAll('[data-editable="99"]')[0].focus();
                   this_menu.remove()
                   // copied.  consolidate
                   edit_menu_for(document.activeElement.id);        // so create one
                   $(":focus").addClass("may_select");
                   console.log("element with fcous is", $(":focus"));
                   console.log("putting focus on", document.getElementById('edit_menu_holder'));
                   document.getElementById('edit_menu_holder').focus();
                   console.log("element with fcous is", $(":focus"));
                   console.log("are we done tabbing to the next item?");

               }
           } else { // we are at the bottom of a block
               alert("Shift-Tab not implemented at the bottom of a block");
           }
       } else {
         console.log("Error:  Shift-Tab not understood when ther eis an active menu");
       }
    } 
    else if (e.code == "Enter" || e.code == "ArrowRight") {
        e.preventDefault();
        console.log("saw a Return (meaning, Enter)");
        console.log("focus is on", $(":focus"));
        // we have just tabbed to a new element.  Tab to move on, return to edit at/near that element
        // But: it makes a difference whether we are at the end of a block
        if (this_choice = document.getElementById('enter_choice')) {
            console.log("this_choice is", this_choice);
            if (this_choice.getAttribute('data-location') == 'stay') {
               var this_menu = document.getElementById("edit_menu_holder");
               block_we_are_reentering = this_menu.previousSibling;
               block_we_are_reentering.classList.remove("may_leave");
               $(block_we_are_reentering).children('[data-editable="99"]')[0].focus();
               this_menu.remove();
               // put  menu on the item at the top of the block_we_are_reentering
                   // this is a repeat of a Tab case, so consolidate
               edit_menu_for(document.activeElement.id);
               $(":focus").addClass("may_select");
               document.getElementById('edit_menu_holder').focus();
               return

            } else {
                var edit_submenu = document.createElement('ol');
                edit_submenu.setAttribute('id', 'edit_menu');

                var to_be_edited = document.getElementById('enter_choice').parentElement.parentElement;
                console.log("to_be_edited", to_be_edited);
                console.log("option", top_menu_options_for(to_be_edited));
                edit_submenu.innerHTML = top_menu_options_for(to_be_edited);
                $("#enter_choice").replaceWith(edit_submenu);
                document.getElementById('choose_current').focus();
                return
            }
        } 
           // otherwise check if there is an action associated to this choice
           else if (document.getElementById('choose_current').hasAttribute("data-action")) {
                var current_active_menu_item = document.getElementById('choose_current');
                var this_action = current_active_menu_item.getAttribute("data-action");
                var to_be_edited = document.getElementById('edit_menu_holder').parentElement;
                if (this_action == "edit") {
                   console.log("going to edit it", to_be_edited);
                   edit_in_place(to_be_edited);
                   } 
                else { alert("unimplemented action: "+ this_action) }
        }
        // otherwise, see if we just selected a top level menu item about location
        // because that involves checking the parent to see what options are possible
          else if (document.getElementById('choose_current').hasAttribute("data-location")) {
            var current_active_menu_item = document.getElementById('choose_current');
            console.log("location infro on",current_active_menu_item);
            if (['before', 'after'].includes(current_active_menu_item.getAttribute("data-location"))) {
            //    $("#choose_current").parent().addClass("past");
                current_active_menu_item.parentElement.classList.add("past");
                current_active_menu_item.removeAttribute("id");
                current_active_menu_item.classList.add("chosen");

                parent_type = document.getElementById('edit_menu_holder').parentElement.parentElement.tagName.toLowerCase();
                console.log("making a menu for", parent_type);
                var edit_submenu = document.createElement('ol');
                edit_submenu.innerHTML = menu_options_for(parent_type, "base");
                console.log("just inserted inner menu_options_for(parent_type)", menu_options_for(parent_type, "inner"));
                current_active_menu_item.insertAdjacentElement("beforeend", edit_submenu);
                document.getElementById('choose_current').focus();
                console.log("focus is on", $(":focus"));
            } else if (current_active_menu_item.getAttribute("data-location") == "enter") {
                this_menu = document.getElementById('edit_menu_holder');
                var object_to_be_entered = this_menu.parentElement;
                this_menu.remove();
                object_to_be_entered.classList.remove("may_select");
                var object_to_be_entered_type = object_to_be_entered.tagName;
             //   alert("Entering " + object_to_be_edited_type + " not implemented yet");
                $(object_to_be_entered).children('[data-editable="99"]')[0].focus();
               // put  menu on the item at the top of the block_we_are_reentering
                   // this is a repeat of a Tab case, so consolidate
                edit_menu_for(document.activeElement.id);
                $(":focus").addClass("may_select");
                document.getElementById('edit_menu_holder').focus();
                return
            // consolidate leave/stay ?
//  the leave/stay is now handles by Tab, so delete the next couple things
            } else if (current_active_menu_item.getAttribute("data-location") == "leave") {
                var object_we_are_in = $('#edit_menu_holder').prev();
                console.log("leaving", object_we_are_in);
                object_we_are_in.classList.remove("may_leave");

            } else if (current_active_menu_item.getAttribute("data-location") == "stay") {
                    // we are at the bottom of a block and want to stay in it, so go to the top of it
                var object_we_are_in = $('#edit_menu_holder').prev();
                object_we_are_in.first('[data-editable="99"]').focus();
            }
        } else { // else check if the selected items leads to a submenu
            console.log("selected a menu item with no action and no location");
            $("#choose_current").parent().addClass("past");
            current_active_menu_item = document.getElementById('choose_current');
            console.log("apparently selected", current_active_menu_item);
            current_active_menu_item.removeAttribute("id");
            current_active_menu_item.setAttribute('class', 'chosen');
 //       current_active_menu_item.setAttribute('style', 'background:#ddf;');
            current_active_menu_item_environment = current_active_menu_item.getAttribute('data-env');

            if (current_active_menu_item_environment in inner_menu_for) {  // object names a collection, so make submenu
                console.log("making a menu for", current_active_menu_item_environment);
                var edit_submenu = document.createElement('ol');
                edit_submenu.innerHTML = menu_options_for(current_active_menu_item_environment, "inner");
     //           console.log("removing id from", current_active_menu_item);
     //           current_active_menu_item.removeAttribute("id");
                current_active_menu_item.insertAdjacentElement("beforeend", edit_submenu);
          //      next_menu_item.setAttribute("id", "choose_current");
                document.getElementById('choose_current').focus();
                console.log("setting focus AA on",next_menu_item);
                next_menu_item.focus();
            } else {  // we just selected an action, so do it
                      // that probably involves adding something before or after a given object
                var new_object_type = current_active_menu_item.getAttribute("data-env");
                var new_object_type_parent = current_active_menu_item.getAttribute("data-env-parent");
                if ( (new_object_type_parent in editing_container_for) || (new_object_type in editing_container_for) ) {
                    object_near_new_object = document.getElementById('edit_menu_holder').parentElement;
                    var before_after = $("#edit_menu_holder > #edit_menu > .chosen").attr("data-location");
     //           alert("attempting to add " + new_object_type + " " + before_after + " " + object_near_new_object.tagName);
                    if (before_after == "before") { new_location = "beforebegin" }
                    else if (before_after == "after") { new_location = "afterend" }
                    object_near_new_object.insertAdjacentElement(new_location, container_for_editing(new_object_type));
           //     document.getElementById('starting_point_for_editing').focus();
                    document.querySelectorAll('[class~="starting_point_for_editing"]')[0].focus();
  //              hack_to_fix_first_textbox_character('starting_point_for_editing');
     //           object_near_new_object.focus();
                    object_near_new_object.classList.remove("may_select");
                    document.getElementById('edit_menu_holder').remove();

                 } else {
                    alert("don't yet know about " + new_object_type);
                    document.getElementById('edit_menu_holder').parentElement.focus();
                    document.getElementById('edit_menu_holder').remove();
                    edit_menu_for(document.activeElement.id);
            // this should be done automatically by edit_menu_for()
                    document.getElementById('edit_menu_holder').focus();
                }
            }

        }
    }  else if (e.code == "ArrowUp") {
        // copied from Tab, so consolidate
        current_active_menu_item = document.getElementById('choose_current');
        next_menu_item = current_active_menu_item.previousSibling;
        console.log("current_active_menu_item", current_active_menu_item, "next_menu_item", next_menu_item);
        if (!next_menu_item) { next_menu_item = current_active_menu_item.parentNode.lastChild }
        console.log("current_active_menu_item", current_active_menu_item, "next_menu_item", next_menu_item);
        current_active_menu_item.removeAttribute("id");
        console.log("current_active_menu_item", current_active_menu_item, "next_menu_item", next_menu_item);
        current_active_menu_item.classList.remove("chosen");
        next_menu_item.setAttribute("id", "choose_current");
        console.log("setting focus on",next_menu_item);
        next_menu_item.focus();
    }  else if (e.code == "Escape" || e.code == "ArrowLeft") {
        console.log("processing ESC");
        if (current_active_menu_item = document.getElementById('choose_current')) {
            console.log("current_active_menu_item", current_active_menu_item);
            previous_selection = current_active_menu_item.parentNode.parentNode;  //current li, up to ol, then up to div or li
            if (previous_selection.tagName == "LI") {
                console.log("going up to the previous selection");
                current_active_menu_item.parentNode.remove();  // remove the ol containing this selection
                previous_selection.focus();
                previous_selection.setAttribute("id", "choose_current");
                previous_selection.classList.remove("chosen");
                previous_selection.parentNode.classList.remove("past");
            } else {  // shoudl be the div#edit_menu_holder
                current_object_to_edit = document.getElementById('edit_menu_holder').parentNode;
                document.getElementById('edit_menu_holder').remove();
                edit_menu_for(current_object_to_edit.id);
                 // just put the entering option
            }
        } else {  // we are at the top of an object and have not decided to edit it
            current_object_being_edited = document.getElementById('edit_menu_holder').parentNode;
            parent_object_to_edit = current_object_being_edited.parentNode;
            console.log("parent_object_to_edit", parent_object_to_edit);
            document.getElementById('edit_menu_holder').remove();
            current_object_being_edited.classList.remove("may_select");
            edit_menu_for(parent_object_to_edit.id);
            parent_object_to_edit.classList.add("may_select");
        }
    } else if ((key_hit = e.code.toLowerCase()) != e.code.toUpperCase()) {  //  supposed to check if it is a letter
        key_hit = key_hit.substring(3);  // remove forst 3 characters, i.e., "key"
        current_active_menu_item = document.getElementById('choose_current');
        console.log('current_active_menu_item',  current_active_menu_item );
        console.log( $(current_active_menu_item) );
          // there can be multiple data-jump, so use ~= to find if the one we are looking for is there
          // and start from the beginning in case the match is earlier  (make the second selector better)
        if ((next_menu_item = $(current_active_menu_item).nextAll('[data-jump~="' + key_hit + '"]:first')[0]) ||
            (next_menu_item = $(current_active_menu_item).prevAll('[data-jump~="' + key_hit + '"]:last')[0])) {  // check there is a menu item with that key
            current_active_menu_item.removeAttribute("id", "choose_current");
            console.log('[data-jump="' + key_hit + '"]');
            console.log( $(current_active_menu_item) );
            console.log("li",  $(current_active_menu_item).next('li') );
            console.log("nextAll", $(current_active_menu_item).nextAll('[data-jump="' + key_hit + '"]:first') );
            console.log("next t-l", $(current_active_menu_item).next('[data-env="theorem-like"]') );
            console.log("current_active_menu_item", current_active_menu_item, "cccc", $(current_active_menu_item).next('[data-jump="' + key_hit + '"]'));
            console.log("next_menu_item", next_menu_item);
            next_menu_item.setAttribute("id", "choose_current");
            next_menu_item.focus();
        } else {
            // not sure what to do if an errelevant key was hit
            console.log("that key does not match any option")
        }
    }
}

console.log("adding tab listener");

document.addEventListener('keydown', logKeyDown);

function logKeyDown(e) {
    if (e.code == "ShiftLeft" || e.code == "ShiftRight" || e.code == "Shift") { return }
    prev_prev_char = prev_char;
    prev_char = this_char;
    this_char = e;
    console.log("logKey",e,"XXX",e.code);
    console.log("are we editing", document.getElementById('actively_editing'));
    console.log("is there already an edit menu?", document.getElementById('edit_menu_holder'));

    var input_region = document.activeElement.tagName;
    console.log("input_region", input_region);
    // if we are writing something, keystrokes usually are just text input
    if (document.getElementById('actively_editing')) {
        console.log("                 we are actively editing");
        if (document.getElementById('local_menu_holder')) {  // we are editing, but are doing so through a local menu
            console.log("document.getElementById('local_menu_holder')", document.getElementById('local_menu_holder'));
            local_menu_navigator(e)
        }  else {
            if (input_region == "INPUT") { return }   // e.preventDefault() 
            else { // input_region is TEXTAREA
                console.log("about to do local_editing_action", this_char.code, prev_char.code, prev_prev_char.code);
                local_editing_action(e) }
        }

    } else {
        main_menu_navigator(e);
    }
}

document.addEventListener('focus', function() {
  console.log('focused: ', document.activeElement)
  prev_prev_focused_element = prev_focused_element;
  prev_focused_element = this_focused_element;
  this_focused_element = document.activeElement;
  $('.in_edit_tree').removeClass('in_edit_tree');
  var edit_tree = $(':focus').parents();
  console.log("edit tree", edit_tree);
//  edit_tree.addClass('in_edit_tree');
  // put little lines on teh right, to show the local heirarchy
  for (var i=0; i < edit_tree.length; ++i) {
//      console.log('edit_tree[i]', edit_tree[i]);
      if (edit_tree[i].getAttribute('id') == "content") { break }
      edit_tree[i].classList.add('in_edit_tree')
  }
}, true);

