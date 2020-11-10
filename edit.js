
console.log(" enabling edit");

//$("p").tabIndex = 0;
$("p").attr("tabindex", 0);

var result;

var menu_neutral_background = "#ddb";
var menu_active_background = "#fdd";

menu_for = {
"section": ["paragraph", "list-like", "theorem-like", "remark-like", "example-like", "image/display-like", "table-like", "minor heading", "subsection", "side-by-side"],
"theorem-like": ["theorem", "proposition", "lemma", "corollary", "hypothesis", "conjecture"],
"list-like": ["ordered list", "unordered list", "dictionary-list"]
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

function base_menu_options_for(component) {
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
    var this_object_type = "pparagraph";
    var this_list = '<li tabindex="-1" id="choose_current" data-env="paragraph" data-action="edit">Edit ' + this_object_type + '</li>';
    this_list += '<li tabindex="-1" data-env="' + this_object_type + '" data-location="enter">Enter ' + this_object_type + '</li>';
    this_list += '<li tabindex="-1" data-env="' + this_object_type + '" data-location="before">Insert before ' + this_object_type + '</li>';
    this_list += '<li tabindex="-1" data-env="' + this_object_type + '" data-location="after">Insert after ' + this_object_type + '</li>';
    return this_list
}

function edit_menu_for(this_obj_id) {
    console.log("make edit menu for", this_obj_id);
//    var this_object_type = "pparagraph";
    var edit_menu_holder = document.createElement('div');
    edit_menu_holder.setAttribute('class', 'edit_menu_holder');
    edit_menu_holder.setAttribute('id', 'edit_menu_holder');
    console.log("adding menu for", this_obj_id);
    document.getElementById(this_obj_id).insertAdjacentElement("afterbegin", edit_menu_holder);

    var enter_option = document.createElement('span');
//    enter_option.setAttribute('class', 'level1 past');
    enter_option.setAttribute('id', 'enter_choice');

//    var this_list = '<li tabindex="-1" id="choose_current" data-env="paragraph" data-action="edit">Edit ' + this_object_type + '</li>';
//    this_list += '<li tabindex="-1" data-env="paragraph" data-action="enter">Enter ' + this_object_type + '</li>';
//    this_list += '<li tabindex="-1" data-env="section">Insert before ' + this_object_type + '</li>';
//    this_list += '<li tabindex="-1" data-env="section">Insert after ' + this_object_type + '</li>';
    enter_option.innerHTML = "edit near here?";
    document.getElementById("edit_menu_holder").insertAdjacentElement("afterbegin", enter_option);

/*
    var edit_menu = document.createElement('div');
    edit_menu.setAttribute('class', 'level1');
    edit_menu.setAttribute('id', 'edit_menu');
    edit_menu.textContent = 'Edit paragraph';
    document.getElementById("edit_menu_holder").insertAdjacentElement("afterbegin", edit_menu);
*/
}

/*
let response = await fetch(url);
console.log("status of response",response.status);
*/


/*
$("p").click(function(){
    console.log("clicked a p");
    $(this).css("background-color", "yellow");
    thisID = $(this).attr('id');
    if( sourceContent[thisID] ) {
        console.log("we have that content")

        var idOfEditContainer = thisID + '_input';
        var idOfEditText = thisID + '_input_text';
        var textarea_editable = document.createElement('textarea');
        textarea_editable.setAttribute('class', 'text_source');
        textarea_editable.setAttribute('id', idOfEditText);
        textarea_editable.setAttribute('style', 'width:105%;');

        var this_content_container = document.createElement('div');
        this_content_container.setAttribute('id', idOfEditContainer);
        $("#" + thisID).replaceWith(this_content_container);

        document.getElementById(idOfEditContainer).insertAdjacentElement("afterbegin", textarea_editable);

        $('#' + idOfEditText).val(sourceContent[thisID]);
        document.getElementById(idOfEditText).focus();
        document.getElementById(idOfEditText).setSelectionRange(0,0);
        textarea_editable.style.height = textarea_editable.scrollHeight + "px";
        console.log("made edit box for", thisID);
        textarea_editable.addEventListener("keypress", function() {
          textarea_editable.style.height = textarea_editable.scrollHeight + "px";
       }, false);
    }
    edit_menu_for(thisID + "_input")
});
*/

function edit_in_place(obj) {
    thisID = obj.getAttribute("id");
    if( sourceContent[thisID] ) {
        var idOfEditContainer = thisID + '_input';
        var idOfEditText = thisID + '_input_text';
        var textarea_editable = document.createElement('textarea');
        textarea_editable.setAttribute('class', 'text_source');
        textarea_editable.setAttribute('id', idOfEditText);
        textarea_editable.setAttribute('style', 'width:105%;');

        var this_content_container = document.createElement('div');
        this_content_container.setAttribute('id', idOfEditContainer);
        $("#" + thisID).replaceWith(this_content_container);

        document.getElementById(idOfEditContainer).insertAdjacentElement("afterbegin", textarea_editable);

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

console.log("adding tab listener");

document.addEventListener('keydown', logKey);

function logKey(e) {
    console.log("logKey",e,"XXX",e.code);
    if (e.code == "Tab") {
       console.log("hit a Tab");

       // we are tabbing along deciding what component to edit
       // so a Tab means to move on
       // so remove the option to edit one object
       if(document.getElementById('enter_choice')) {
           $("#edit_menu_holder").parent().removeClass("may_select");
           document.getElementById('edit_menu_holder').remove()
       }
       // and add the option to edit the next object
       if (!document.getElementById('edit_menu_holder')) {  // we are not already navigating a menu
           $(":focus").addClass("may_select");
           edit_menu_for(document.activeElement.id);        // so create one
           return
       }
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

/*
       if(document.activeElement.tagName == "P") {
           console.log("removing old menu");
           var oldmenu = document.getElementById('edit_menu_holder');
           if (oldmenu) { oldmenu.remove() }
           console.log("making ner menu");
           edit_menu_for(document.activeElement.id)
       }
*/
    }
    else if (e.code == "Enter") {
        console.log("saw a Return");
        // we have just tabbed to a new element.  Tab to move on, return to edit at/near that element
        if (document.getElementById('enter_choice')) {
            var edit_submenu = document.createElement('ol');
            edit_submenu.setAttribute('id', 'edit_menu');

            to_be_edited = document.getElementById('enter_choice').parentElement;
            console.log("to_be_edited", to_be_edited);
            console.log("option", top_menu_options_for(to_be_edited));
            edit_submenu.innerHTML = top_menu_options_for(to_be_edited);
            $("#enter_choice").replaceWith(edit_submenu);
            document.getElementById('choose_current').focus();
            return
        }
        // otherwise, see if we just selected a menu item
        $("#choose_current").parent().addClass("past");
        current_active_menu_item = document.getElementById('choose_current');
        console.log("apparently selected", current_active_menu_item);
        current_active_menu_item.removeAttribute("id");
        current_active_menu_item.setAttribute('class', 'chosen');
 //       current_active_menu_item.setAttribute('style', 'background:#ddf;');
        var edit_submenu = document.createElement('ol');
        if (current_active_menu_item.hasAttribute("data-action")) {
            to_be_edited = document.getElementById('edit_menu_holder').parentElement;
            
            document.getElementById('edit_menu_holder').remove();
            this_action = current_active_menu_item.getAttribute("data-action");
            if (this_action == "edit") {
               console.log("going to edit it", to_be_edited);
               edit_in_place(to_be_edited);
               } 
        } // here should look for data-location           
        var this_item_type = current_active_menu_item.getAttribute("data-env");
        edit_submenu.innerHTML = base_menu_options_for(this_item_type);
        current_active_menu_item.insertAdjacentElement("beforeend", edit_submenu);
    }
}


