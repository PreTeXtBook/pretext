
/* preliminary hacks */


//$("p").tabIndex = 0;
$("p").attr("tabindex", 0);
$(".autopermalink > a").attr("tabindex", -1);

$("#akX > *").attr("data-editable", 99);

/* the code */

console.log(" enabling edit");

// we have to keep track of multiple consecutive carriage returns
this_char = "";
prev_char = "";
prev_prev_char = "";

// sometimes we have to prevent Tab from changing focus
this_focused_element = "";
prev_focused_element = "";
prev_prev_focused_element = "";

var result;

var menu_neutral_background = "#ddb";
var menu_active_background = "#fdd";

menu_for = {
"section": ["paragraph", "list-like", "theorem-like", "remark-like", "example-like", "image/display-like", "table-like", "minor heading", "subsection", "side-by-side"],
"theorem-like": ["theorem", "proposition", "lemma", "corollary", "hypothesis", "conjecture"],
"list-like": ["ordered list", "unordered list", "dictionary-list"],
"blockquote": ["paragraph"],
"metadata": ["index entries", "notation"],
"p": ["text decoration", "abbreviation", "symbols", "ref or link"],
"text decoration": ["emphasis", "foreign word", "book title", "inline quote"],
"abbreviation": ["ie", "eg", "etc", "et al"],
"symbols": ["ellipsis", "trademark", "copyright"],
"ref or link": ["ref to an id", "citation", "hyperlink"]
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

function base_menu_options_for(COMPONENT) {
     component = COMPONENT.toLowerCase();
     if (component in menu_for) {
         component_items = menu_for[component]
     } else {
         component_items = ["placeholder 1", "placeholder 2-like", "placeholder 3", "placeholder 4", "placeholder 5"];
     }

//     this_menu = "<ol>";
     this_menu = "";
     for (var i=0; i < component_items.length; ++i) {
         this_item = component_items[i];
         if(i==0) { this_menu += '<li tabindex="-1" id="choose_current" data-env="' + this_item + '">' }
         else { this_menu += '<li tabindex="-1" data-env="' + this_item + '">' }
         this_menu += this_item + '</li>';
     }
//     this_menu += "</ol>";

     return this_menu
}

function top_menu_options_for(this_obj_id) {
    var this_object_type = "paragraph";
    var this_list = '<li tabindex="-1" id="choose_current" data-env="paragraph" data-action="edit">Edit ' + this_object_type + '</li>';
    this_list += '<li tabindex="-1" data-env="' + this_object_type + '" data-location="enter">Enter ' + this_object_type + '</li>';
    this_list += '<li tabindex="-1" data-env="' + this_object_type + '" data-location="before">Insert before</li>';
    this_list += '<li tabindex="-1" data-env="' + this_object_type + '" data-location="after">Insert after</li>';
    this_list += '<li tabindex="-1" data-env="' + this_object_type + '">Metadata</li>';
    this_list += '<li tabindex="-1" data-env="' + this_object_type + '">Move or delete</li>';
    return this_list
}

function edit_menu_for(this_obj_id, motion="entering") {
    console.log("make edit menu", motion, "for", this_obj_id);

    if (motion == "entering") { menu_location = "afterbegin" }
    else { menu_location = "afterend" }  // motion is 'leaving'

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
//    var enter_option = document.createElement('span');
//    enter_option.setAttribute('id', 'enter_choice');
//
//    enter_option.innerHTML = "edit near here?";
//    document.getElementById("edit_menu_holder").insertAdjacentElement("afterbegin", enter_option);
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
    
    enter_option.innerHTML = base_menu_options_for("p");

    document.getElementById("local_menu_holder").insertAdjacentElement("afterbegin", enter_option);
   // prev_focused_element.focus();
    // next_menu_item.focus();
}

/*
let response = await fetch(url);
console.log("status of response",response.status);
*/

function container_for_editing(obj_type) {
    var this_content_container = document.createElement('div');
    this_content_container.setAttribute('id', "actively_editing");

    if (obj_type == "paragraph") {
        this_content_container.innerHTML = '<textarea id="actively_editing_paragraph" class="starting_point_for_editing" style="width:100%;" placeholder="' + obj_type + '"></textarea>';
    } else if ( menu_for["theorem-like"].includes(obj_type) ) {
        var title = "<div><b>" + obj_type + "&nbsp;NN</b>&nbsp;";
        title += '<input id="actively_editing_title" class="starting_point_for_editing" placeholder="Optional title" type="text"/>';
        title += '<input id="actively_editing_id" placeholder="Optional Id" class="input_id" type="text"/>';
        title += '</div>';
        var statement = '<div><span class="group_description">statement (paragraphs, images, lists, etc)</span><textarea id="actively_editing_statement" style="width:100%;" placeholder="first paragraph of statement"></textarea></div>';
        var proof = '<div><span class="group_description">optional proof (paragraphs, images, lists, etc)</span><textarea id="actively_editing_proof" style="width:100%;" placeholder="first paragraph of optional proof"></textarea></div>';

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
    if( sourceContent[thisID] ) {

        var this_content_container = document.createElement('div');
        this_content_container.setAttribute('id', "actively_editing");
        this_content_container.setAttribute('data_source_id', thisID);
        $("#" + thisID).replaceWith(this_content_container);

        var idOfEditContainer = thisID + '_input';
   //     var idOfEditText = thisID + '_input_text';
        var idOfEditText = 'editing' + '_input_text';
        var textarea_editable = document.createElement('textarea');
        textarea_editable.setAttribute('class', 'text_source');
        textarea_editable.setAttribute('id', idOfEditText);
        textarea_editable.setAttribute('style', 'width:100%;');

  //      document.getElementById(idOfEditContainer).insertAdjacentElement("afterbegin", textarea_editable);
        document.getElementById('actively_editing').insertAdjacentElement("afterbegin", textarea_editable);

        $('#' + idOfEditText).val(sourceContent[thisID]);
        document.getElementById(idOfEditText).focus();
        document.getElementById(idOfEditText).setSelectionRange(0,0);
        textarea_editable.style.height = textarea_editable.scrollHeight + "px";
        console.log("made edit box for", thisID);
        textarea_editable.addEventListener("keypress", function() {
          textarea_editable.style.height = textarea_editable.scrollHeight + "px";
       });
    }
}

var sourceContent = {
   "cak": '<em>Synonyms</em>: separate - detached - distinct - abstract.',
   "UvL": '    Defining <em>discrete mathematics</em>\n    is hard because defining <em>mathematics</em> is hard.\n    What is mathematics?\n    The study of numbers?\n\
    In part, but you also study functions and lines and triangles and parallelepipeds and vectors and\n\
    <ellipsis/>.\n\
    Or perhaps you want to say that mathematics is a collection of tools that allow you to solve problems.\n\
    What sort of problems?\n\
    Okay, those that involve numbers,\n\
    functions, lines, triangles,\n\
    <ellipsis/>.\n\
    Whatever your conception of what mathematics is,\n\
    try applying the concept of <q>discrete</q> to it, as defined above.\n\
    Some math fundamentally deals with <em>stuff</em>\n\
    that is individually separate and distinct.'
}

function local_menu_navigator(e) {
    e.preventDefault();
    if (e.code == "Tab") {
        if (!document.getElementById('local_menu_holder')) {  // no local menu, so make one
            local_menu_for('actively_editing');
//            local_menu_for('actively_editing_paragraph');
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

function local_editing_action(e) {
    if (e.code == "Escape") {
        console.log("putting focus back");
        prev_focused_element.focus();
    } else if (e.code == "Tab") {
        e.preventDefault();
        console.log("making a local menu");
        local_menu_navigator(e);
    } else if (e.code == "Return") {
    //    e.preventDefault();
        if (prev_char == "Return" && prev_prev_char == "Return") {
            save_current_editing()
        }
    }
}

function main_menu_navigator(e) {  // we are not currently editing
                              // so we are building the menu for the user to decide what/how to edit

 // too early   e.preventDefault();  // we are navigating a menu, we we control what keystrokes mean
    if (e.code == "Tab" || e.code == "ArrowDown") {
       e.preventDefault();
       console.log("hit a Tab (or ArrowDown");
       console.log("focus is on", $(":focus"));

       // we are tabbing along deciding what component to edit
       // so a Tab means to move on
       // so remove the option to edit one object
       if(document.getElementById('enter_choice')) {
           console.log("there already is an 'enter_choice'");
           $("#edit_menu_holder").parent().removeClass("may_select");
           console.log("item to get next focus",$("#edit_menu_holder").parent().next('[tabindex="0"]'), "which has length", $("#edit_menu_holder").parent().next('[tabindex="0"]').length);
           if(!$("#edit_menu_holder").parent().next('[tabindex="0"]').length) { //at the end of a block.  Do we leave or go to the top?
               e.preventDefault();
               var enclosing_block = $("#edit_menu_holder").parent().parent()[0];
               console.log("at the end of", enclosing_block, "with id", enclosing_block.id);
               document.getElementById('edit_menu_holder').remove();
               edit_menu_for(enclosing_block.getAttribute("id"), "leaving");
               console.log("focus is on",  $(":focus"));
               enclosing_block.classList.add("may_leave");
               document.getElementById('choose_current').focus();
               console.log("document.getElementById('choose_current')", document.getElementById('choose_current'), $(":focus"));
               return
           }  else {
               $("#edit_menu_holder").parent().next('[data-editable="99"]').focus();
               document.getElementById('edit_menu_holder').remove()
           }
       }
       // and add the option to edit the next object
       if (!document.getElementById('edit_menu_holder')) {  // we are not already navigating a menu
           e.preventDefault();
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

    }
    else if (e.code == "Enter" || e.code == "ArrowRight") {
        e.preventDefault();
        console.log("saw a Return");
        console.log("focus is on", $(":focus"));
        // we have just tabbed to a new element.  Tab to move on, return to edit at/near that element
        if (document.getElementById('enter_choice')) {
            var edit_submenu = document.createElement('ol');
            edit_submenu.setAttribute('id', 'edit_menu');

            var to_be_edited = document.getElementById('enter_choice').parentElement;
            console.log("to_be_edited", to_be_edited);
            console.log("option", top_menu_options_for(to_be_edited));
            edit_submenu.innerHTML = top_menu_options_for(to_be_edited);
            $("#enter_choice").replaceWith(edit_submenu);
            document.getElementById('choose_current').focus();
            return
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

                parent_type = document.getElementById('edit_menu_holder').parentElement.parentElement.tagName;
                console.log("making a menu for", parent_type);
                var edit_submenu = document.createElement('ol');
                edit_submenu.innerHTML = base_menu_options_for(parent_type);
                console.log("just inserted base_menu_options_for(parent_type)", base_menu_options_for(parent_type));
                current_active_menu_item.insertAdjacentElement("beforeend", edit_submenu);
                document.getElementById('choose_current').focus();
                console.log("focus is on", $(":focus"));
            } else if (current_active_menu_item.getAttribute("data-location") == "enter") {
                var object_to_be_edited = document.getElementById('edit_menu_holder').parentElement;
                var object_to_be_edited_type = object_to_be_edited.tagName;
                alert("Entering " + object_to_be_edited_type + " not implemented yet");
                object_to_be_edited.classList.remove("may_select");
                document.getElementById('edit_menu_holder').remove();
            // consolidate leave/stay ?
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

            if (current_active_menu_item_environment in menu_for) {  // object names a collection, so make submenu
                console.log("making a menu for", current_active_menu_item_environment);
                var edit_submenu = document.createElement('ol');
                edit_submenu.innerHTML = base_menu_options_for(current_active_menu_item_environment);
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
                object_near_new_object = document.getElementById('edit_menu_holder').parentElement;
                var before_after = $("#edit_menu_holder > #edit_menu > .chosen").attr("data-location");
     //           alert("attempting to add " + new_object_type + " " + before_after + " " + object_near_new_object.tagName);
                if (before_after == "before") { new_location = "beforebegin" }
                else if (before_after == "after") { new_location = "afterend" }
                object_near_new_object.insertAdjacentElement(new_location, container_for_editing(new_object_type));
           //     document.getElementById('starting_point_for_editing').focus();
                document.querySelectorAll('[class="starting_point_for_editing"]')[0].focus();
                hack_to_fix_first_textbox_character('starting_point_for_editing');
     //           object_near_new_object.focus();
                object_near_new_object.classList.remove("may_select");
                document.getElementById('edit_menu_holder').remove();
            }

        }
    }  else if (e.code == "ArrowUp") {
        alert("Sorry, up arrow not implemented yet.\nBut when it is, it will move to the previous item on this sub-menu");
    }  else if (e.code == "ArrowLeft") {
        alert("Sorry, left arrow not implemented yet.\nBut when it is, it will move to the previous sub-menu");
    }
}

console.log("adding tab listener");

document.addEventListener('keydown', logKey);

function logKey(e) {
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
        if (document.getElementById('local_menu_holder')) {  // we are editing, but are doing so through a local menu
            console.log("document.getElementById('local_menu_holder')", document.getElementById('local_menu_holder'));
            local_menu_navigator(e)
        }  else {
            if (input_region == "INPUT") { return }   // e.preventDefault() 
            else { // input_region is TEXTAREA
                local_editing_action(e) }
        }

    } else {
        main_menu_navigator(e);
 //       alert("what has Tab done?");
 //       e.preventDefault();
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

