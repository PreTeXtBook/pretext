
/* preliminary hacks */


//$("p").tabIndex = 0;
// $("p").attr("tabindex", -1);
$(".autopermalink > a").attr("tabindex", -1);

$("#akX > *").attr("data-editable", 99);
// var editable_objects = ["p", "ol", "ul", "li", "article", "blockquote", "section"];
var editable_objects = ["p", "ol", "ul", "article", "blockquote", "section"];
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

var menu_neutral_background = "#ddb";
var menu_active_background = "#fdd";

var recent_editing_actions = [];

var current_editing = {
    "level": 0,
    "location": [0],
    "tree": [document.getElementById("hPw")]
}

function randomstring(len) {
    if (!len) { len = 10 }
    return (Math.random() + 1).toString(36).substring(2,len)
}

function removeItemFromList(lis, value) {
  var index = lis.indexOf(value);
  if (index > -1) {
    lis.splice(index, 1);
  }
  return lis;
}

var renamable = {
    "definition-like": ["definition", "conjecture", "axiom", "principle", "heuristic", "hypothesis", "assumption"],
    "theorem-like": ["lemma", "proposition", "theorem", "corollary", "claim", "fact", "identity", "algorithm"],
    "remark-like": ["remark", "warning", "note", "observation", "convention", "insight"],
    "section-like": ["section", "subsection", "exercises"]
}

function object_class_of(tag) {
    var known_types = ["theorem-like", "definition-like", "remark-like", "section-like"];

    for (var j=0; j<known_types.length; ++j) {
        if (editing_container_for[known_types[j]].includes(new_tag)) {
            return known_types[j]
        }

    }

    return "unknown"
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
            ["list or table", "list-like"],
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
"ol": [["list item", "li"]],
"article": [["paragraph", "p"],
            ["list or table", "list-like"],
            ["math/chemistry/code", "math-like", "c"],
            ["image/video/sound", "display-like", "v"]],
"p": [["emphasis-like"], ["formula"], ["abbreviation"], ["symbol"], ["ref or link", "ref"]]
}

function inner_menu_for() {

    console.log("recent_editing_actions", recent_editing_actions, "xx", recent_editing_actions != []);
    var the_past_edits = [];
    if(recent_editing_actions.length) {
         the_past_edits = recent_editing_actions.map(x => [x])}
    else { the_past_edits = [["no chnages yet"]] }

    console.log("the_past_edits", the_past_edits);

the_inner_menu = {
"theorem-like": [["lemma"],
                 ["proposition"],
                 ["theorem"],
                 ["corollary"],
                 ["claim", "claim", "m"],
                 ["fact"],
                 ["identity"],
                 ["algorithm"]],
"definition-like": [["definition"],
                   ["conjecture", "conjecture"],
                   ["axiom", "axiom", "x"],
                   ["principle", "principle"],
                   ["heuristic", "heuristic", "u"],
                   ["hypothesis", "hypothesis", "y"],
                   ["assumption", "assumption", "s"]],
"list-like": [["itemized list", "list"], ["dictionary list", "dl"], ["table"]],
"ol": [["list item", "li"]],
"section-like": [["section"], ["subsection", "subsection", "b"], ["titled paragraph", "paragraphs"], ["reading questions", "rq"], ["exercises"]],
"project-like": [["exercise"], ["activitiy"], ["investigation"], ["exploration", "exploration", "x"], ["project"]],
"remark-like": [["remark"], ["warning"], ["note"], ["observation"], ["convention"], ["insight"]],
"example-like": [["example"], ["question"], ["problem"]],
"display-like": [["image"], ["image with caption", "imagecaption", "m"], ["video"], ["video with caption", "videocaption", "d"], ["audio"]],
"aside-like": [["aside"], ["historical"], ["biographical"]],
"layout-like": [["side-by-side"], ["assemblage"], ["biographical aside"], ["titled paragraph", "paragraphs"]],
"math-like": [["math display", "mathdisplay"], ["chemistry display", "chemistrydisplay"], ["code listing", "code", "l"]],
"quoted": [["blockquote"], ["poem"], ["music"]],
"interactives": [["sage cell", "sagecell"], ["webwork"], ["asymptote"], ["musical score", "musicalscore"]],
"metadata": [["index entries"], ["notation"]],
"emphasis-like": [["emphasis"], ["foreign word", "foreign"], ["book title"], ["article title"], ["inline quote"], ["name of a ship"]],
// "abbreviation": ["ie", "eg", "etc", "et al"],  // i.e., etc., ellipsis, can just be typed.
"symbol": [["trademark"], ["copyright"], ["money"]],
"money": [["$ dollar"], ["&euro; euro"], ["&pound; pound"], ["&yen; yen"]],
"ref": [["reference withing this document"], ["citation"], ["hyperlink"]],
"undo": the_past_edits
}
    return the_inner_menu
}

// this should be created from inner_menu_for
editing_container_for = { "p": 1,
 "theorem-like": ["theorem", "proposition", "lemma", "corollary", "claim", "fact", "identity", "algorithm"],
 "definition-like": ["definition", "conjecture", "axiom", "hypothesis", "principle", "heuristic", "assumption"],
"remark-like": ["remark", "warning", "note", "observation", "convention", "insight"],
"section-like": ["section", "subsection", "paragraphs", "rq", "exercises"],
"ol": ["item"]
}

// each tag has [ptx_tag, [html_start, html_end]]
// Note: end of html_start is missing, so it is easier to add attributes
inline_tags = {'em': ['em', ['<em class="emphasis"', "</em>"]], 
               'term': ['term', ['<dfn class="terminology"', '</dfn>']]
}
math_tags = {'m': ['m', ['\\(', '\\)']] }

title_like_tags = {
    "h1": [],   //  all the hN are .heading, so probably should use that
    "h2": [],
    "h3": [],
    "h4": [],
    "h5": [],
    "h6": [],  // title or creator or ...
    "figcaption": []  // plain text betweem last </span> and </figcaption>
}

editing_tips = {
    "p": ["two RETurns to separate paragraphs",
          "three RETurns to end editing a paragraph",
          "TAB to insert emphasis, math, special characters, etc",
          "ESC to stop editing and save",
          "TAB to insert a reference or index entry",
          "TAB to insert musical characters, species name, inline code, etc"],
    "title": ["RETurn to save title",
              "TAB for a reference, special characters, etc"]
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

function standard_title_form(object_id) {
    the_object = internalSource[object_id];
    object_type = the_object["ptxtag"];  // need to use that to determin the object_type_name
    object_type_name = object_type;
    the_parent = the_object["parent"];
    the_parent_id = the_parent[0];
    the_parent_component = the_parent[1];

    var title_form = "<div><b>" + object_type_name + "&nbsp;#N</b>&nbsp;";
    title_form += '<span id="editing_title_holder">';
    title_form += '<input id="actively_editing_title" class="starting_point_for_editing" data-source_id="' + object_id + '" data-component="' + 'title' + '" placeholder="Optional title" type="text"/>';

    title_form += '&nbsp;<span class="group_description">(' + editing_tip_for("title") + ')</span>';
/*
    title_form += '<input id="actively_editing_id" placeholder="Optional Id" class="input_id" type="text"/>';
*/
    title_form += '</span>';  // #editing_title_holder
    title_form += '</div>';

    return title_form
}

function menu_options_for(COMPONENT, level) {
     var menu_for;
     var component = COMPONENT.toLowerCase();
     if (level == "base") { menu_for = base_menu_for }
     else if (level == "change") {
         console.log("menu_options_for", component);
         objectclass = object_class_of(component);
         var equivalent_objects = renamable[objectclass];
         var replacement_list = removeItemFromList(equivalent_objects, component);
         var this_menu = "";
         for (var i=0; i < replacement_list.length; ++i) {
             this_menu += '<li tabindex="-1" data-action="change-env-to" data-env="' + replacement_list[i] + '"'; 
             if (i==0) { this_menu += ' id="choose_current"'}
             this_menu += '>';
             this_menu += replacement_list[i];
             this_menu += '</li>';
         }
         return this_menu
     } else { menu_for = inner_menu_for() }
     console.log("in menu_options_for", component);
     if (component in menu_for) {
         component_items = menu_for[component]
     } else {
         component_items = [["placeholder 1"], ["placeholder 2-like"], ["placeholder 3"], ["placeholder 4"], ["placeholder 5"]];
     }

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
             if (this_item_name.match(/^[a-z]/i)) {
                 this_item_name = this_item_name.replace(this_item_shortcut, '<b>' + this_item_shortcut + '</b>');
             }
         } else {
             this_menu += 'data-jump="' + this_item_name.charAt(0) + '"';
         }
         if (i==0) { this_menu += ' id="choose_current"'}
         this_menu += '>';

         if (this_item_name.match(/^[a-z]/i)) {
             first_character = this_item_name.charAt(0);
             this_item_name = this_item_name.replace(first_character, "<b>" + first_character + "</b>");
         }

         this_menu += this_item_name 
                 // little right triangle if there is a submenu
         if (this_item_label in inner_menu_for()) { this_menu += '<div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div>' }
         this_menu += '</li>';
         
     }

     return this_menu
}

function top_menu_options_for(this_obj) {
    console.log("top_menu_options_for aa", this_obj);

    var this_list = "";

    if (this_obj.classList.contains("heading")) {
        this_obj_parent = this_obj.parentElement;
        console.log("heading options for bbb", this_obj_parent); 
        this_obj_parent_id = this_obj_parent.id;
        this_obj_parent_source = internalSource[this_obj_parent_id];
        this_obj_environment = this_obj_parent_source["ptxtag"];

        console.log("this_obj_environment", this_obj_environment);
        
        this_list = '<li tabindex="-1" id="choose_current" data-env="p" data-action="edit">Change the title</li>';
        this_list += '<li tabindex="-1" data-action="change-env">Change "' + this_obj_environment + '" to <div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div></li>';
    } else {
        var this_object_type = this_obj.tagName;   //  needs to examine other attributes and then look up a reasonable name
//consolidate this redundancy
        this_obj_id = this_obj.id;
        this_obj_source = internalSource[this_obj_id];
        console.log("this_obj_source", this_obj_source);
        this_obj_environment = this_obj_source["ptxtag"];
        if (this_object_type == "P") {
            this_list = '<li tabindex="-1" id="choose_current" data-env="p" data-action="edit">Edit ' + this_obj_environment + '</li>';
            var editable_children = next_editable_of(this_obj, "children");
            console.log("editable_children", editable_children);
     //       if ($(this_obj).children('.heading > [data-editable="99"], [data-editable="99"]').length) {
            if (editable_children.length) {
                console.log("$(this_obj).children('.heading > [data-editable=99], [data-editable=99]')", $(this_obj).children('.heading > [data-editable="99"], [data-editable="99"]'));
                this_list += '<li tabindex="-1" data-env="' + this_object_type + '" data-location="enter">Enter ' + this_obj_environment + '</li>';
            }
        } else {
            console.log("are there children", $(this_obj).children('.heading > [data-editable="99"], [data-editable="99"]'));
    //        console.log("are there children", editable_children.length);
            this_list += '<li tabindex="-1" id="choose_current" data-env="' + this_object_type + '" data-location="enter">Enter ' + this_obj_environment + '</li>';
       }

        this_list += '<li tabindex="-1" data-env="' + this_object_type + '" data-location="beforebegin">Insert before<div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div></li>';
        this_list += '<li tabindex="-1" data-env="' + this_object_type + '" data-location="afterend">Insert after<div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div></li>';
        this_list += '<li tabindex="-1" data-env="' + this_object_type + '">Move or delete<div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div></li>';
        this_list += '<li tabindex="-1" data-env="' + "metaadata" + '">Metadata<div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div></li>';
        this_list += '<li tabindex="-1" data-env="' + "undo" + '">Undo<div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div></li>';
    }
    return this_list
}

function edit_menu_for(this_obj_or_id, motion) {
    console.log("make edit menu", motion, "for", this_obj_or_id);

    // delete the old menu, if it exists
    if (current_menu = document.getElementById('edit_menu_holder')) {
        console.log("current_menu", current_menu);
        console.log("this_choice", document.getElementById('enter_choice'));
        if (this_choice = document.getElementById('enter_choice')) {
            if (this_choice.getAttribute("data-location") == "stay") {
                current_menu.previousSibling.classList.remove("may_leave")
            } else {
                current_menu.parentElement.classList.remove("may_select");
            }
        }
   //     this_obj.classList.remove("may_select");
   //     this_obj.classList.remove("may_leave");
   //     current_menu.parentElement.classList.remove("may_select");
   //     current_menu.previousSibling.classList.remove("may_leave");
        current_menu.remove();
    }

    if (!this_obj_or_id) {
        console.log("error: empty this_obj_or_id", motion);
        return ""
    }

    if (typeof this_obj_or_id === 'string') {
        this_obj = document.getElementById(this_obj_or_id)
    } else {
        this_obj = this_obj_or_id
    }

    if (motion == "entering") {
        menu_location = "afterbegin";
        this_obj.classList.remove("may_leave"); 
        this_obj.classList.add("may_select");
        if (this_obj.tagName.toLowerCase() in inline_tags) {
            this_obj.classList.add("inline");
        }
    } else { menu_location = "afterend";
        this_obj.classList.remove("may_select");
        this_obj.classList.add("may_leave"); 
        console.log("added may_leave to", this_obj)
    }  // when motion is 'leaving'

    var edit_menu_holder = document.createElement('div');
//    edit_menu_holder.setAttribute('class', 'edit_menu_holder');
    edit_menu_holder.setAttribute('id', 'edit_menu_holder');
    edit_menu_holder.setAttribute('tabindex', '-1');
    console.log("adding menu for", this_obj_or_id, "menu_location", menu_location);
    console.log("which has tag", this_obj.tagName);
    console.log("does", this_obj.classList, "include type", this_obj.classList.contains("type"));

    this_obj.insertAdjacentElement(menu_location, edit_menu_holder);

    var edit_option = document.createElement('span');
    edit_option.setAttribute('id', 'enter_choice');

    if (motion == "entering") {
        console.log("inline_tags", inline_tags, "tag", this_obj.tagName.toLowerCase());
        if (this_obj.tagName.toLowerCase() in inline_tags) {
            edit_option.innerHTML = "change this?";
            edit_option.setAttribute('data-location', 'inline');
        } else if (this_obj.tagName.toLowerCase() in title_like_tags) { 
            edit_option.innerHTML = "modify this?";
            edit_option.setAttribute('data-location', 'inline');
        } else if (this_obj.classList.contains("type")) {
            // need to code this better:  over-writing edit_option
            edit_option = document.createElement('ol');
            edit_option.setAttribute('id', 'edit_menu');
            this_obj_parent_id = this_obj.parentElement.parentElement.id;
            this_obj_environment = internalSource[this_obj_parent_id]["ptxtag"];
            edit_option.innerHTML = '<li id="choose_current" tabindex="-1" data-action="change-env">Change "' + this_obj_environment + '" to <div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div></li>';
            edit_option.setAttribute('data-location', 'inline');
        } else if (this_obj.classList.contains("creator") || this_obj.classList.contains("title")) {
            // need to code this better:  over-writing edit_option
            edit_option = document.createElement('ol');
            edit_option.setAttribute('id', 'edit_menu');
            this_obj_parent_id = this_obj.parentElement.parentElement.id;
            this_obj_environment = internalSource[this_obj_parent_id]["ptxtag"];
            edit_option.innerHTML = '<li id="choose_current" tabindex="-1" data-action="change-title">Change title</li>';
            edit_option.setAttribute('data-location', 'inline');
        } else {
            edit_option.innerHTML = "edit near here?";
            edit_option.setAttribute('data-location', 'next');
        }
    } else {
        edit_option.setAttribute('data-location', 'stay');
        edit_option.innerHTML = "continue editing " + this_obj.tagName;
    }
    document.getElementById("edit_menu_holder").insertAdjacentElement("afterbegin", edit_option);
    document.getElementById('edit_menu_holder').focus();
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

function next_editable_of(obj, relationship) {
    var next_to_edit;
    console.log("finding", relationship, "editable of", obj);
    if (relationship == "children") {
    //    next_to_edit = $(obj).find('> .heading > [data-editable="99"], > [data-editable="99"]')
        next_to_edit = $(obj).find('>li > [data-editable="99"], > .heading > [data-editable="99"], > [data-editable="99"]')
    //    next_to_edit = $(obj).children('[data-editable="99"]')
    } else if (relationship == "siblings") {
        next_to_edit = $(obj).nextAll('[data-editable="99"]')
    } else if (relationship == "previoussiblings") {
        next_to_edit = $(obj).prevAll('[data-editable="99"]')
    }

    console.log(next_to_edit);
    return next_to_edit
}

function create_object_to_edit(new_tag, new_objects_sibling, relative_placement) {

    console.log("create_object_to_edit", new_tag, new_objects_sibling, relative_placement);
              // first insert a placeholder to edit-in-place
    var new_id = randomstring();
        // we won;t need all of these, so re-think when these are created
    var new_content_p_id = randomstring();
    var new_statement_p_id = randomstring();
    var new_proof_p_id = randomstring();
    var edit_placeholder = document.createElement("span");
    edit_placeholder.setAttribute('id', new_id);
    new_objects_sibling.insertAdjacentElement(relative_placement, edit_placeholder);

                  // then create the empty internalSource for the new object
    new_source = {"xml:id": new_id, "permid": "", "ptxtag": new_tag, "title": ""}
    if (new_tag == "p") {
        new_source["content"] = "";
    } else if (new_tag == "li") {  // creating an li, which needs one p inside
        var new_p_id = randomstring();
        internalSource[new_p_id] = {"xml:id": new_p_id, "permid": "", "ptxtag": "p", "content": "just a tesssss sssst", "parent": [new_id, "content"]}
        new_source["content"] = "<&>" + new_p_id + "<;>";
    } else if (new_tag == "list") {  // creating a list, which needs one item to begin.
                                   // that item is an li contining a p
        var new_li_id = randomstring();
        var new_p_id = randomstring();
        internalSource[new_p_id] = {"xml:id": new_p_id, "permid": "", "ptxtag": "p", "content": "just a tesssss sssst", "parent": [new_li_id, "content"]}
        internalSource[new_li_id] = {"xml:id": new_li_id, "permid": "", "ptxtag": "li", "content": "<&>" + new_p_id + "<;>", "parent": [new_id, "content"] }
        new_source["content"] = "<&>" + new_li_id + "<;>";
    } else if (editing_container_for["theorem-like"].includes(new_tag)) {
        new_source["statement"] = "<&>" + new_statement_p_id + "<;>";
        internalSource[new_statement_p_id] = { "xml:id": new_statement_p_id, "permid": "", ptxtag: "p",
                      content: "", "parent": [new_id, "statement"] }
        new_source["proof"] = "<&>" + new_proof_p_id + "<;>";
        internalSource[new_proof_p_id] = { "xml:id": new_proof_p_id, "permid": "", ptxtag: "p",
                      content: "", "parent": [new_id, "proof"] }
    } else if (editing_container_for["definition-like"].includes(new_tag)) {
        new_source["statement"] = "<&>" + new_statement_p_id + "<;>";
        internalSource[new_statement_p_id] = { "xml:id": new_statement_p_id, "permid": "", ptxtag: "p",
                      content: "", "parent": [new_id, "statement"] }
    } else if (editing_container_for["remark-like"].includes(new_tag)) {
        new_source["statement"] = "<&>" + new_content_p_id + "<;>";
        internalSource[new_content_p_id] = { "xml:id": new_content_p_id, "permid": "", ptxtag: "p",
                      content: "", "parent": [new_id, "statement"] }
    } else if (editing_container_for["section-like"].includes(new_tag)) {
        new_source["content"] = "<&>" + new_content_p_id + "<;>";
        internalSource[new_content_p_id] = { "xml:id": new_content_p_id, "permid": "", ptxtag: "p",
                      content: "", "parent": [new_id, "content"] }
    }  else {   // note: not all cases have been covered
        new_source["content"] = "<&>" + new_content_p_id + "<;>";
        internalSource[new_content_p_id] = { "xml:id": new_content_p_id, "permid": "", ptxtag: "p",
                      content: "", "parent": [new_id, "content"] }
    }
                  // and describe where it goes
    console.log("new_objects_sibling",new_objects_sibling);
    var sibling_id = new_objects_sibling.id;
    var parent_description = internalSource[sibling_id]["parent"];  
    new_source["parent"] = parent_description;
    internalSource[new_id] = new_source
   // we have made the new object, but we still have to put it in the correct location

    var the_current_arrangement = internalSource[parent_description[0]][parent_description[1]];
    console.log("         the_current_arrangement", the_current_arrangement);

    var object_neighbor = new RegExp('(<&>' + sibling_id + '<;>)');
    var neighbor_with_new = '$1' + '\n<&>' + new_id + '<;>'   //if the new goes after the old
    if (relative_placement == "beforebegin") {  neighbor_with_new = '<&>' + new_id + '<;>\n' + '$1' }
    new_arrangement = the_current_arrangement.replace(object_neighbor, neighbor_with_new);
    internalSource[parent_description[0]][parent_description[1]] = new_arrangement;
    console.log("         new_arrangement", new_arrangement);
    console.log("tried to insert", new_id, "next to", sibling_id, "in", the_current_arrangement)

//    thisID = new_id;
//    thisTagName = new_tag;
    return edit_placeholder
}

function edit_in_place(obj) {

    if (thisID = obj.getAttribute("id")) {
        console.log("will edit in place", thisID);
        thisTagName = obj.tagName.toLowerCase();
    } else {  // editing somethign without an id, so probably is a title or caption
        if (obj.classList.contains("heading")) {
            console.log("changing a heading");
            console.log("except we don;t know how to do that")
        } else {
            console.log("error:  I don't know how to edit", obj)
        }
        return ""
    }

     // this only works for paragraphs,
     // whing may be right, becaise ixisting content is mostly titles and paragraphs
    if ( internalSource[thisID] ) {
      new_tag = internalSource[thisID]["ptxtag"];
      new_id = thisID;  // track down why new_id is in the code
      console.log("new_tag is", new_tag, "from", internalSource[thisID]);
      if (new_tag == "p") {
        var this_content_container = document.createElement('div');
        this_content_container.setAttribute('id', "actively_editing");
        $("#" + thisID).replaceWith(this_content_container);

        var idOfEditContainer = thisID + '_input';
   //     var idOfEditText = thisID + '_input_text';
        var idOfEditText = 'editing' + '_input_text';
        var paragraph_editable = document.createElement('div');
        paragraph_editable.setAttribute('contenteditable', 'true');
        paragraph_editable.setAttribute('class', 'text_source paragraph_input');
        paragraph_editable.setAttribute('id', idOfEditText);
        paragraph_editable.setAttribute('data-source_id', thisID);
        paragraph_editable.setAttribute('data-parent_id', internalSource[thisID]["parent"][0]);
        paragraph_editable.setAttribute('data-parent_component', internalSource[thisID]["parent"][1]);

        document.getElementById('actively_editing').insertAdjacentElement("afterbegin", paragraph_editable);

        console.log("setting", $('#' + idOfEditText), "to have contents", internalSource[thisID]["content"]);
        the_contents = internalSource[thisID]["content"]; 
        the_contents = expand_condensed_source_html(the_contents, "edit");
        $('#' + idOfEditText).html(the_contents);
        document.getElementById(idOfEditText).focus();
  //      document.getElementById(idOfEditText).setSelectionRange(0,0);
  //      textarea_editable.style.height = textarea_editable.scrollHeight + "px";
        console.log("made edit box for", thisID);
        this_char = "";
        prev_char = "";
      } else if (new_tag == "li") {
        var this_content_container = document.createElement('li');
        this_content_container.setAttribute('id', "actively_editing");
        $("#" + thisID).replaceWith(this_content_container);
        
        var idOfEditContainer = thisID + '_input';
        var idOfEditText = 'editing' + '_input_text';
        var paragraph_editable = document.createElement('div');
        paragraph_editable.setAttribute('contenteditable', 'true');
        paragraph_editable.setAttribute('class', 'text_source paragraph_input');
        paragraph_editable.setAttribute('id', idOfEditText);
        paragraph_editable.setAttribute('data-source_id', thisID);
        paragraph_editable.setAttribute('data-parent_id', internalSource[thisID]["parent"][0]);
        paragraph_editable.setAttribute('data-parent_component', internalSource[thisID]["parent"][1]);
  
        document.getElementById('actively_editing').insertAdjacentElement("afterbegin", paragraph_editable);
  
        console.log("setting", $('#' + idOfEditText), "to have contents", internalSource[thisID]["content"]);
        the_contents = internalSource[thisID]["content"]; 
        the_contents = expand_condensed_source_html(the_contents, "edit");
        $('#' + idOfEditText).html(the_contents);
        document.getElementById(idOfEditText).focus();
  //      document.getElementById(idOfEditText).setSelectionRange(0,0);
        console.log("made edit box for", thisID);
        this_char = "";
        prev_char = "";

      } else if (new_tag == "list") {
          console.log("list edit_in_place", obj)
          var this_content_container = document.createElement('ol');
          this_content_container.setAttribute('id', "actively_editing");
          this_content_container.setAttribute('data-source_id', thisID);
          this_content_container.setAttribute('data-parent_id', internalSource[thisID]["parent"][0]);
          this_content_container.setAttribute('data-parent_component', internalSource[thisID]["parent"][1]);
          this_content_container.setAttribute('data-objecttype', 'list');
       //   var list_content = '<li class="editing_li"><p id="editing_input_text" contenteditable="true" class="paragraph_input" tabindex="-1">xxxx cccc vvvv bbba</p></li>';
          var list_content = internalSource[thisID]["content"];
          console.log("expanding list_content", list_content, "as edit");
     //     list_content = expand_condensed_source_html(list_content, "inner");
          list_content = expand_condensed_source_html(list_content, "edit");
          this_content_container.innerHTML = list_content;
          $("#" + thisID).replaceWith(this_content_container);
          $("#editing_input_text").focus();
          console.log("now put focus on", document.activeElement)
      } else if (editing_container_for["definition-like"].includes(new_tag) ||
                editing_container_for["theorem-like"].includes(new_tag) ||
                editing_container_for["remark-like"].includes(new_tag) ||
                editing_container_for["section-like"].includes(new_tag)) {
// only good for creating a new theorem or definition, not editing in place
// think about thaat use case:  once it exists, do we ever edit the theorem as a unit?

        console.log("edit_in_place", obj);
        var objecttype = object_class_of(new_tag);
        var this_content_container = document.createElement('div');
        this_content_container.setAttribute('id', "actively_editing");
        this_content_container.setAttribute('data-objecttype', objecttype);

        var title = standard_title_form(new_id);

        var statement_container_start = '<div class="editing_statement">';
        var statement_container_end = '</div>';
        var editingregion_container_start = '<div class="editing_p_holder">'
        var editingregion_container_end = '</div>'
        var statementinstructions = '<span class="group_description">statement (paragraphs, images, lists, etc)</span>';
        console.log("this object:", internalSource[new_id]);
        var new_statement_p_id;
        if (editing_container_for["section-like"].includes(new_tag)) {
            new_statement_p_id = internalSource[new_id]["content"];
        } else {
            new_statement_p_id = internalSource[new_id]["statement"];
        }
        new_statement_p_id = new_statement_p_id.replace(/<.>/g, "");  // because statement looked like <&>abcde<;> 
        var statementeditingregion = '<div contenteditable="true" class="paragraph_input" id="actively_editing_statement" style="width:98%;" placeholder="first paragraph of statement" data-source_id="' + new_statement_p_id + '" data-parent_id="' + new_id + '" data-parent_component="statement"></div>';
        var statement = statement_container_start + editingregion_container_start;
        statement += statementinstructions;
        statement += statementeditingregion;
        statement += editingregion_container_end + statement_container_end;

        var proof = "";
        if (editing_container_for["theorem-like"].includes(new_tag)) {
            var proof_container_start = '<div class="editing_proof">';
            var proof_container_end = '</div>';
            var proofinstructions = '<span class="group_description">optional proof (paragraphs, images, lists, etc)</span>';
            var new_proof_p_id = internalSource[new_id]["statement"];
            new_proof_p_id = new_proof_p_id.replace(/<.>/g, "");
            var proofeditingregion = '<div id="actively_editing_proof" class="paragraph_input" contenteditable="true" style="width:98%;min-height:6em;" placeholder="first paragraph of optional proof"  data-source_id="' + new_proof_p_id + '" data-parent_id="' + new_id + '" data-parent_component="proof">What is <b>bold</b> or <em>emphasized</em>?</div>';

            proof = proof_container_start + editingregion_container_start;
            proof += proofinstructions;
            proof += proofeditingregion;
            proof += editingregion_container_end + proof_container_end;
        }

        this_content_container.innerHTML = title + statement + proof;

        $("#" + thisID).replaceWith(this_content_container);
        $("#actively_editing_title").focus();
      } else if (false && editing_container_for["remark-like"].includes(new_tag)) {

        console.log("edit_in_place", obj)
        var this_content_container = document.createElement('div');
        this_content_container.setAttribute('id', "actively_editing");
        this_content_container.setAttribute('data-objecttype', 'remark-like');

        var title = standard_title_form(new_id);

        var content_container_start = '<div class="editing_content">';
        var content_container_end = '</div>';
        var editingregion_container_start = '<div class="editing_p_holder">'
        var editingregion_container_end = '</div>'
        var contentinstructions = '<span class="group_description">content (paragraphs, images, lists, etc)</span>';
        var contenteditingregion = '<div contenteditable="true" class="paragraph_input" id="actively_editing_statement" style="width:98%;" placeholder="first paragraph of content" data-source_id="' + new_content_p_id + '" data-parent_id="' + new_id + '" data-parent_component="content"></div>';
        var content = content_container_start + editingregion_container_start;
        content += contentinstructions;
        content += contenteditingregion;
        content += editingregion_container_end + content_container_end;

        this_content_container.innerHTML = title + content

        $("#" + thisID).replaceWith(this_content_container);
        $("#actively_editing_title").focus();
     } else {
          console.log("I do not know how to edit", new_tag)
     }
   } else {
        console.log("Error: edit_in_place of object that is not already known", obj);
        console.log("What is known:", internalSource)
     }
}

var internalSource = {  // currently the key is the HTML id
   "hPw": {"xml:id": "", "permid": "hPw", "ptxtag": "section", "title": "What is Discrete Mathematics?",
           "content": "<&>akX<;>\n<&>UvL<;>\n<&>ACU<;>\n<&>gKd<;>\n<&>MRm<;>\n<&>udO<;>\n<&>sYv<;>\n<&>ZfE<;>"},
   "MRm": {"xml:id": "", "permid": "MRm", "ptxtag": "p", "title": "", "parent": ["hPw","content"],
           "content": "One way to get a feel for the subject is to consider the types of problems you solve in discrete math.\nHere are a few simple examples:"},
   "cak": {"xml:id": "", "permid": "cak", "ptxtag": "p", "title": "", "parent": ["akX","content"],
           "content": "<&>357911<;>: separate - detached - distinct - abstract."},
   "akX": {"xml:id": "", "permid": "akX", "ptxtag": "blockquote", "title": "", "parent": ["hPw","content"],
           "content": "<&>PLS<;>\n<&>vTb<;>\n<&>cak<;>"},
   "UvL": {"xml:id": "", "permid": "UvL", "ptxtag": "p", "title": "","parent": ["hPw","content"],
           "content": "    Defining <em>discrete mathematics</em>\n    is hard because defining <em>mathematics</em> is hard.\n    What is mathematics?\n    The study of numbers?\n In part, but you also study functions and lines and triangles and parallelepipeds and vectors and\n <ellipsis/>.\n Or perhaps you want to say that mathematics is a collection of tools that allow you to solve problems.\n What sort of problems?\n Okay, those that involve numbers,\n functions, lines, triangles,\n <ellipsis/>.\n Whatever your conception of what mathematics is,\n try applying the concept of <q>discrete</q> to it, as defined above.\n Some math fundamentally deals with <em>stuff</em>\n that is individually separate and distinct."},
   "357911": {"xml:id": "356711", "permid": "", "ptxtag": "em", "title": "",
           "content": 'Synonyms'},
   "sYv": {"xml:id": "", "permid": "sYv", "ptxtag": "p", "parent": ["hPw","content"],
           "content": "One way to get a feel for the subject is to consider the types of problems you solve in discrete math. Here are a few simple examples:"},
   "ACU": {"xml:id": "", "permid": "ACU", "ptxtag": "p", "parent": ["hPw","content"],
           "content": "In an algebra or calculus class, you might have found a particular set of numbers (maybe the set of numbers in the range of a function). You would represent this set as an interval: <&>223344<;> is the range of <&>112233<;> since the set of outputs of the function are all real numbers <m>0</m> and greater. This set of numbers is NOT discrete. The numbers in the set are not separated by much at all. In fact, take any two numbers in the set and there are infinitely many more between them which are also in the set."},
   "112233": {"xml:id": "", "permid": "", "ptxtag": "m", "parent": ["ACU","content"],
           "content": "f(x)=x^2"},
   "udO": {"xml:id": "", "permid": "udO", "ptxtag": "investigation", "parent": ["hPw","content"],
           "content": "<&>Iht<;><&>ooC<;>"},
   "Iht": {"xml:id": "", "permid": "Iht", "ptxtag": "p", "parent": ["udO","content"],
           "content": "Note: Throughout the text you will see <em>Investigate!</em>\nactivities like this one.\nAnswer the questions in these as best you can to give yourself a feel for what is coming next."},
   "ooC": {"xml:id": "", "permid": "ooC", "ptxtag": "list", "parent": ["udO","content"],
           "content": "<&>mzp<;><&>SGy<;><&>yNH<;><&>eUQ<;>"},
   "mzp": {"xml:id": "", "permid": "mzp", "ptxtag": "li", "parent": ["ooC","content"],
           "content": "<&>LbZ<;>"},
   "LbZ": {"xml:id": "", "permid": "LbZ", "ptxtag": "p", "parent": ["mzp","content"],
           "content": "The most popular mathematician in the world is throwing a party for all of his friends.\n As a way to kick things off, they decide that everyone should shake hands.\n Assuming all 10 people at the party each shake hands with every other person\n (but not themselves,\n obviously)\n exactly once, how many handshakes take place?"},
   "SGy": {"xml:id": "", "permid": "SGy", "ptxtag": "li", "parent": ["ooC","content"],
           "content": "<&>rji<;>"},
   "rji": {"xml:id": "", "permid": "rji", "ptxtag": "p", "parent": ["SGy","content"],
           "content": "At the warm-up event for Oscar's All Star Hot Dog Eating Contest, Al ate one hot dog.\n Bob then showed him up by eating three hot dogs.\n Not to be outdone, Carl ate five.\n This continued with each contestant eating two more hot dogs than the previous contestant.\n How many hot dogs did Zeno (the 26th and final contestant) eat?\n How many hot dogs were eaten all together?"},
   "223344": {"xml:id": "", "permid": "", "ptxtag": "m", "parent": ["ACU","content"],
           "content": "[0, \\infty)"}
}



function local_menu_navigator(e) {
    e.preventDefault();
    console.log("in the local_menu_navigator");
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

// there are two types of expansion to be done:
//    expand internal tags
//    convert hand-written ptx to HTML
    output_text = expand_condensed_source_html(output_text);

    output_text = output_text.replace(/<term>/g, "<b>"); 
    output_text = output_text.replace(/<\/term>/g, "</b>"); 
    return(output_text)
}

function save_internal_contents(some_text) {

    // some_text must be a paragraph with mixed content only contining
    // non-nested tags
    the_text = some_text;
    console.log("            xxxxxxxxxx  the_text is", the_text);
    if (the_text.includes('data-editable="99" tabindex="-1">')) {
        return the_text.replace(/<([^<]+) data-editable="99" tabindex="-1">(.*?)<[^<]+>/g, save_internal_cont)
    } else if(the_text.includes('$ ')) {   // not general enough
         return the_text.replace(/ \$([^\$]+)\$ /g, extract_new_math)
    } else {
    return the_text
    }
}

function extract_new_math(match, math_content) {
    new_math_id = randomstring();
    internalSource[new_math_id] = { "xml:id": new_math_id, "permid": "", "ptxtag": "m",
                          "content": math_content}
    return " <&>" + new_math_id + "<;> "
}

function save_internal_cont(match, contains_id, the_contents) {
    this_id = contains_id.replace(/.*id="(.+?)".*/, '$1');

    console.log("id", this_id, "now has contents", the_contents);
    internalSource[this_id]["content"] = the_contents;
    return "<&>" + this_id + "<;>"
}
function assemble_internal_version_changes() {
    console.log("current active element to be saved", document.activeElement);

    var possibly_changed_ids_and_entry = [];
    var nature_of_the_change = "";

    var object_being_edited = document.activeElement;
    var location_of_change = object_being_edited.parentElement;

//    if (object_being_edited.tagName == "TEXTAREA") {
    if (object_being_edited.classList.contains("paragraph_input")) {
        nature_of_the_change = "replace";
        var textbox_being_edited = object_being_edited;  //document.getElementById('actively_editing_p');
   //     var paragraph_content = textbox_being_edited.value;
        var paragraph_content = textbox_being_edited.innerHTML;
        console.log("paragraph_content from innerHTML", paragraph_content);
        paragraph_content = paragraph_content.trim();

        var cursor_location = textbox_being_edited.selectionStart;

        console.log("cursor_location", cursor_location, "out of", paragraph_content.length, "paragraph_content", paragraph_content);

        // does the textbox contain more than one paragraph?
  //      var paragraph_content_list = paragraph_content.split("\n\n");
        var paragraph_content_list = paragraph_content.split("<div><br></div>");
        var num_paragraphs = paragraph_content_list.length;

        var parent_and_location = [object_being_edited.getAttribute("data-parent_id"), object_being_edited.getAttribute("data-parent_component")];
        var this_arrangement_of_objects = "";
        console.log("parent_and_location", parent_and_location);
        console.log("of ", object_being_edited);
        for(var j=0; j < num_paragraphs; ++j) {
            // probably each paragraph is wrapped in meaningless div tags
            var this_paragraph_contents_raw = paragraph_content_list[j];
            this_paragraph_contents_raw = this_paragraph_contents_raw.replace(/<\/div><div>/g, "\n");
            this_paragraph_contents_raw = this_paragraph_contents_raw.replace(/<div>/g, "");
            this_paragraph_contents_raw = this_paragraph_contents_raw.replace(/<\/div>/g, "");
            this_paragraph_contents_raw = this_paragraph_contents_raw.replace(/&nbsp;/g, " ");
            this_paragraph_contents_raw = this_paragraph_contents_raw.replace(/ <br>/g, " ");
            this_paragraph_contents_raw = this_paragraph_contents_raw.replace(/<br>/g, " ");
            this_paragraph_contents_raw = this_paragraph_contents_raw.trim();
            if (!this_paragraph_contents_raw) { console.log("empty paragraph"); continue }
            console.log("this_paragraph_contents_raw", this_paragraph_contents_raw);
            if (j == 0 && (prev_id = textbox_being_edited.getAttribute("data-source_id"))) {
                if (prev_id in internalSource) {
                    // the content is referenced, so we update the referenced content
               //     id_of_content = internalSource[prev_id]["content"];
               //     internalSource[id_of_content] = paragraph_content_list[j]
                       // need to check internal content, such as em or math
                    this_paragraph_contents = save_internal_contents(this_paragraph_contents_raw);
                    if (internalSource[prev_id]["content"] != this_paragraph_contents) {
                        internalSource[prev_id]["content"] = this_paragraph_contents;
                        recent_editing_actions.push("changed paragraph " + prev_id)
                    }
                    possibly_changed_ids_and_entry.push([prev_id, "content"]);
                    this_arrangement_of_objects = internalSource[parent_and_location[0]][parent_and_location[1]];
                } else {
                    console.log("error:  existing tag from input", prev_id, "not in internalSource")
                }
            } else {  // a newly created paragraph
                var this_object_internal = {"ptxtag": "p", "title": ""}; //p don't have title
                this_object_label = randomstring();
                this_object_internal["xmlid"] = this_object_label;
                this_object_internal["permid"] = "";
                this_object_internal["parent"] = parent_and_location;
        //        console.log("need to add paragraph",this_object_label, "inside", this_arrangement_of_objects, "after (or after after)", prev_id);

                // put the new p after the previous p in the string describing the neighboring contents
                var object_before = new RegExp('(<&>' + prev_id + '<;>)');
                this_arrangement_of_objects = this_arrangement_of_objects.replace(object_before, '$1' + '\n<&>' + this_object_label + '<;>');
                prev_id = this_object_label;
                
                this_paragraph_contents = save_internal_contents(this_paragraph_contents_raw);
                this_object_internal["content"] = this_paragraph_contents;
                internalSource[this_object_label] = this_object_internal
                recent_editing_actions.push("added paragraph " + this_object_label);
                possibly_changed_ids_and_entry.push([this_object_label, "content"]);
            }
        }
        console.log("this_arrangement_of_objects was",  internalSource[parent_and_location[0]][parent_and_location[1]]);
        internalSource[parent_and_location[0]][parent_and_location[1]] = this_arrangement_of_objects;
        console.log("this_arrangement_of_objects is", this_arrangement_of_objects);
    } else if (object_being_edited.tagName == "INPUT") {

  // current code assume the INPUT is a title.  Other cases?

        nature_of_the_change = "replace";
        var line_being_edited = object_being_edited;  //document.getElementById('actively_editing_p');
        var line_content = line_being_edited.value;
        line_content = line_content.trim();
        console.log("the content (is it a title?) is", line_content);
        var owner_of_change = object_being_edited.getAttribute("data-source_id");
        var component_being_changed = object_being_edited.getAttribute("data-component");
        console.log("component_being_changed", component_being_changed, "within", owner_of_change);
        // update the title of the object
        internalSource[owner_of_change][component_being_changed] = line_content;
        recent_editing_actions.push("changed title " + owner_of_change);
        possibly_changed_ids_and_entry.push([owner_of_change, "title"]);

    } else {
        alert("don;t know how to assemble_internal_version_changes of", object_being_edited.tagName)
    }
    console.log("finished assembling internal version, which is now:",internalSource);
    return [nature_of_the_change, location_of_change, possibly_changed_ids_and_entry]
}

function expand_condensed_source_html(text, context) {
    console.log("iiiiiii     in expand_condensed_source_html", text);
    if (text.includes("<&>")) {
        console.log("     eeeeeeeeee      expand_condensed_source_html", text);
        if (context == "edit") {
            return text.replace(/<&>(.*?)<;>/g,expand_condensed_src_edit)
         } else {
            return text.replace(/<&>(.*?)<;>/g,expand_condensed_src_html)
         }
    } else {
    return text
    }
}
function expand_condensed_src_html(match, the_id) {
    return html_from_internal_id(the_id, "inner")
}
function expand_condensed_src_edit(match, the_id) {
    return html_from_internal_id(the_id, "edit")
}

function html_from_internal_id(the_id, is_inner) {
       // the outer element needs to be constructed as document.createElement
       // but the inner content is just plain text
    var the_object = internalSource[the_id];
    console.log("making html of", the_object, "is_inner", is_inner);
    var ptxtag = the_object["ptxtag"];

    var the_html_objects = [];

    if (ptxtag == "p") {
        var the_content = the_object["content"];
        if ("edit inner".includes(is_inner)) {
            var opening_tag="<p ", closing_tag="</p>";

            if(is_inner == "edit") {
                opening_tag += 'id="editing_input_text" data-parent_id="' + the_id + '" data-parent_component="content"'
                opening_tag += ' contenteditable="true"'
                opening_tag += ' class="paragraph_input"'
            } else if (is_inner == "inner") {

                opening_tag += 'id="' + the_id + '"';
                opening_tag += ' data-editable="99" tabindex="-1"';
            }

            opening_tag += '>';
            return opening_tag + expand_condensed_source_html(the_content, is_inner) + closing_tag
        }

        html_of_this_object = document.createElement('p');
        html_of_this_object.setAttribute("data-editable", 99);
        html_of_this_object.setAttribute("tabindex", -1);
        html_of_this_object.setAttribute("id", the_id);

        html_of_this_object.innerHTML = the_content
        the_html_objects.push(html_of_this_object);

    } else if (ptxtag == "li") {   // assume is_inner?
        var the_content = the_object["content"];
        console.log("inserting an li with content", the_content);
        the_content = expand_condensed_source_html(the_content, is_inner);
        console.log("which now has content", the_content);

        if ("edit inner".includes(is_inner)) {
                // should the id be the_id ?
            var opening_tag = '<li id="' + the_id + '"';
            opening_tag += ' data-editable="99" tabindex="-1"';
            opening_tag += '>';
            var closing_tag = '</li>';
            return opening_tag + the_content + closing_tag
        }

        html_of_this_object = document.createElement('li');
        html_of_this_object.setAttribute("data-editable", 99);
        html_of_this_object.setAttribute("tabindex", -1);
        html_of_this_object.setAttribute("id", the_id);

        html_of_this_object.innerHTML = the_content
        the_html_objects.push(html_of_this_object);
    } else if (ptxtag in inline_tags) {   // assume is_inner?
        var opening_tag = inline_tags[ptxtag][1][0];
        opening_tag += ' id="' + the_id + '"data-editable="99" tabindex="-1">';
        var closing_tag = inline_tags[ptxtag][1][1];
        return opening_tag + the_object["content"] + closing_tag
  //      return '<em id="' + the_id + '"data-editable="99" tabindex="-1">' + the_object["content"] + '</em>';
    } else if (ptxtag in math_tags) {
        // here we are assuming the tag is 'm'
        var opening_tag = '<span class="edit_inline_math"';
        var closing_tag = '</span>';
        if (is_inner == "edit") {
            opening_tag += ' id="' + the_id + '"data-editable="99" tabindex="-1">';
        } else {
            opening_tag = math_tags[ptxtag][1][0];
            closing_tag = math_tags[ptxtag][1][1];
        }
        return opening_tag + the_object["content"] + closing_tag
    } else if (editing_container_for["definition-like"].includes(ptxtag) ||
               editing_container_for["theorem-like"].includes(ptxtag) ||
               editing_container_for["remark-like"].includes(ptxtag) ||
               editing_container_for["section-like"].includes(ptxtag)) {
        // this is messed up:  need a better way to track *-like
        var objectclass = object_class_of(ptxtag);
        var headertag = "h6";
        if (editing_container_for["section-like"].includes(ptxtag)) {
             headertag = "h2"  // need to make that dynamic
        }

        object_in_html = document.createElement("article");
        object_in_html.setAttribute("class", objectclass + " " + ptxtag);
        object_in_html.setAttribute("tabindex", -1);
        object_in_html.setAttribute("data-editable", 99);

        object_title = the_object["title"];

        object_in_html.setAttribute("id", the_id);

        object_heading_html = '<' + headertag;
        object_heading_html += ' class="heading" data-parent_id="' + the_id + '">';
        var objecttype_capped = ptxtag.charAt(0).toUpperCase() + ptxtag.slice(1);
        object_heading_html += '<span class="type" data-editable="99" tabindex="-1">' + objecttype_capped + '</span>';
        object_heading_html += '<span class="space">' + " " + '</span>';
        object_heading_html += '<span class="codenumber">' + "#N" + '</span>';

        if (object_title) {
            object_heading_html += '<span class="space">' + " " + '</span>';
            if (objectclass == "section-like") {
                object_heading_html += '<span class="title" data-editable="99" tabindex="-1">' + object_title + '</span>';
            } else {
                object_heading_html += '<span class="creator" data-editable="99" tabindex="-1">(' + object_title + ')</span>';
            }
        }
        object_heading_html += '<span class="period">' + "." + '</span>';
        object_heading_html += '</' + headertag + '>';

        var object_statement_ptx = the_object["statement"];
        if (editing_container_for["section-like"].includes(ptxtag)) {
            var object_statement_ptx = the_object["content"];
        } else {
            var object_statement_ptx = the_object["statement"];
        }

        object_statement_html =  expand_condensed_source_html(object_statement_ptx);

        object_in_html.innerHTML = object_heading_html + object_statement_html;

        the_html_objects.push(object_in_html);

        if (objectclass == "theorem-like") {
            proof_in_html = document.createElement("article");
            proof_in_html.setAttribute("class", "hiddenproof");
            proof_in_html.innerHTML = '<a data-knowl="" class="id-ref proof-knowl original" data-refid="hk-Jkl"><h6 class="heading" data-editable="99" tabindex="-1"><span class="type">Proof<span class="period">.</span></span></h6></a>';

            the_html_objects.push(proof_in_html)
        }

    } else {
         alert("don't know how to make html from", the_object)
    }
    return the_html_objects
}

function insert_html_version(these_changes) {

    nature_of_the_change = these_changes[0];
    location_of_change = these_changes[1];
    possibly_changed_ids_and_entry = these_changes[2];

    console.log("nature_of_the_change", nature_of_the_change);
    console.log("location_of_change", location_of_change);
    console.log("possibly_changed_ids_and_entry", possibly_changed_ids_and_entry);

    // we make HTML version of the objects with ids possibly_changed_ids_and_entry,
    // and then insert those into the page.  

    if (nature_of_the_change != "replace") {
        console.log("should be replace, since it is the edit form we are replacing");
        alert("should be replace, since it is the edit form we are replacing")
    }

    console.log("possibly_changed_ids_and_entry", possibly_changed_ids_and_entry);
    for (var j=0; j < possibly_changed_ids_and_entry.length; ++j) {
        this_object_id = possibly_changed_ids_and_entry[j][0];
        this_object_entry = possibly_changed_ids_and_entry[j][1];
        this_object = internalSource[this_object_id];
        if (this_object["ptxtag"] == "p") {
            var object_as_html = document.createElement('p');
            object_as_html.setAttribute("data-editable", 99);
            object_as_html.setAttribute("tabindex", -1);
            object_as_html.setAttribute("id", this_object_id);
            object_as_html.innerHTML = ptx_to_html(this_object[this_object_entry]);
            location_of_change.insertAdjacentElement('beforebegin', object_as_html);
        } else if (this_object_entry == "title") {
            var object_as_html = document.createElement('span');
  //          object_as_html.setAttribute("data-editable", 99);
  //          object_as_html.setAttribute("tabindex", -1);
            object_as_html.setAttribute("class", "title");
            object_as_html.innerHTML = ptx_to_html(this_object[this_object_entry]);
            console.log("inserting",object_as_html,"before",location_of_change);
            location_of_change.insertAdjacentElement('beforebegin', object_as_html);
        } else {
            alert("I don; tknow how to make a", this_object["ptxtag"]);
        }
    }
    location_of_change.remove();

    // call mathjax, in case the new vontent contains math
    MathJax.Hub.Queue(['Typeset', MathJax.Hub, this_object_id]);
    return object_as_html  // the most recently added object, which we may want to
                           // do something, like add an editing menu
}

function save_current_editing() {

    var currentState = internalSource;

    console.log("saving", currentState);
    localStorage.setObject("savededits", currentState);
    return "";
}

function retrieve_previous_editing() {
    var old_internal_source = localStorage.getObject("savededits");
    if (old_internal_source) {
        internalSource = old_internal_source
    }
}

function local_editing_action(e) {
    console.log("in local_editing_action for" ,e.code);
    if (e.code == "Tab") {
        e.preventDefault();
        console.log("making a local menu");
        local_menu_navigator(e);
    } else if (e.code == "Escape") {
            e.preventDefault();
            these_changes = assemble_internal_version_changes();
            final_added_object = insert_html_version(these_changes);
            edit_menu_for(final_added_object.id, "entering");
            save_current_editing()
    } else if (e.code == "Enter") {
        console.log("saw a Ret");
        if (document.activeElement.tagName == "INPUT") {
            console.log("probably saving a title");
            e.preventDefault();
            these_changes = assemble_internal_version_changes();
            final_added_object = insert_html_version(these_changes);
            console.log("final_added_object", final_added_object);
// assumes we are editing a theorem-like.  Need to generalize
            document.getElementById("actively_editing_statement").focus();
      //      document.getElementById("actively_editing_statement").setSelectionRange(0,0);
            this_char = "";
            prev_char = "";
            save_current_editing()

        } else if (prev_char.code == "Enter" && prev_prev_char.code == "Enter") {
  // same as ESC above:  consolidate
            console.log("need to save");
            e.preventDefault();
            these_changes = assemble_internal_version_changes();
            final_added_object = insert_html_version(these_changes);
            // if there is a textarea ahead, go there.  Otherwise menu the last thing added
      //      if (next_textarea = document.querySelector('textarea')) {
            if (next_textarea = document.querySelector('.paragraph_input')) {
                next_textarea.focus();
       //         next_textarea.setSelectionRange(0,0);
                this_char = "";
                prev_char = "";
            } else if (editing_placeholder = document.getElementById("actively_editing")) {
                console.log("still editing", editing_placeholder, "which contains", final_added_object);
                var this_parent = internalSource[final_added_object.id]["parent"];
                console.log("final_added_object parent", internalSource[final_added_object.id]["parent"]);
                the_whole_object = html_from_internal_id(this_parent[0]);
                console.log("the_whole_object", the_whole_object);
                for (var j = the_whole_object.length - 1; j >= 0; --j) {
                    document.getElementById("actively_editing").insertAdjacentElement("afterend", the_whole_object[j])
                }
                $("#actively_editing").remove();
          //      $("#actively_editing").replaceWith(the_whole_object[0]);  // later handle multiple additions
                edit_menu_for(this_parent[0], "entering");
            } else {
                edit_menu_for(final_added_object.id, "entering");
            }
            save_current_editing()
        }
    } else {
        console.log("e.code was not one of those we were looking for", e)
    }
}

function main_menu_navigator(e) {  // we are not currently editing
                              // so we are building the menu, and possibly moving aroung the document,
                              //for the user to decide what/how to edit

// There are 3 modes:
//   #enter_choice, data-location="next"
//   #enter_choice, data-location="stay"
// above means we are deciding whenter to edit/enter/leave and object, or to move on
//   #choose_current
// 3rd option means we already have a menu

    if (theEnterChoice = document.getElementById("enter_choice")) {
        console.log("enter_choice", e);
        var theMotion = theEnterChoice.getAttribute("data-location");
        var object_of_interest;
        if (theMotion == "stay") {
            object_of_interest = theEnterChoice.parentElement.previousSibling;
        } else {
            object_of_interest = theEnterChoice.parentElement.parentElement;
        }
        console.log("      MMN: want to", theMotion, "on", object_of_interest, "from", theEnterChoice)

        console.log("current_editing", current_editing);
        console.log("theEnterChoice", theEnterChoice);
        var current_level = current_editing["level"];
        var current_location = current_editing["location"][current_level];
        var current_siblings =  current_editing["tree"][current_level];
        console.log("current_level", current_level, "current_location", current_location, "current_siblings", current_siblings);

        if ((e.code == "Tab" || e.code == "ArrowDown") && !e.shiftKey) {
            e.preventDefault();
            // go to next sibling, or stage to exit if on last sibling
            if (current_location == (current_siblings.length - 1)) {
     //           if (theMotion == "next") {  //at the end, so make "stay" menu on the parent
     //               console.log("staying");
     //               edit_menu_for(object_of_interest, "stay")
     //           } else { //and end, so want to leave
                    current_level -= 1;
                    current_location = current_editing["location"][current_level];
                    current_editing["level"] = current_level;
                    current_editing["location"][current_level] = current_location;
                    current_siblings = current_editing["tree"][current_level];
          //          if (current_location == (current_siblings.length - 1)) {
              console.log("stay menu A");
                    object_of_interest.classList.remove("may_leave");
                    object_of_interest.classList.remove("may_elect");
                        edit_menu_for(current_siblings[current_location], "leaving")
          //          } else {
          //              edit_menu_for(current_siblings[current_location], "entering")
          //          }
      //          }
            } else {
                console.log("moving to the next editable sibling");
                console.log(current_location, "was", current_editing);
                current_location += 1;
                object_of_interest.classList.remove("may_leave");
                object_of_interest.classList.remove("may_elect");
              console.log("stay menu B");
         //       current_editing["location"][current_level] += 1;
                current_editing["location"][current_level] = current_location;
                console.log(current_location, "is", current_editing);
                edit_menu_for(current_siblings[current_location], "entering")
            }
        } else if ((e.code == "Tab" && e.shiftKey) || e.code == "ArrowUp") {  // Shift-Tab to prevous object
            e.preventDefault();
            // go to previous sibling, or up one if on first sibling
            if (current_location == 0) {
                if (!current_level) { return "" } // already at the top, so nowhere to go, so do nothing
// A1
                current_level -= 1;
                current_editing["level"] = current_level;
                current_location = current_editing["location"][current_level];
                current_siblings = current_editing["tree"][current_level];
                edit_menu_for(current_siblings[current_location], "entering")
            } else {
                current_location -= 1;
                current_editing["location"][current_level] = current_location;
                edit_menu_for(current_siblings[current_location], "entering")
            }
        } else if (e.code == "Escape" || e.code == "ArrowLeft") {
            e.preventDefault();
            if (!current_level) { return "" } // already at the top, so nowhere to go, so do nothing
// copied from A1
                current_level -= 1;
                current_editing["level"] = current_level;
                current_location = current_editing["location"][current_level];
                current_siblings = current_editing["tree"][current_level];
                edit_menu_for(current_siblings[current_location], "entering")
        } else if (e.code == "Enter" || e.code == "ArrowRight") {
            e.preventDefault();
            if (theMotion == "stay") {
                edit_menu_for(object_of_interest, "entering");  // should that be current_location?
                return ""
            } 
            var edit_submenu = document.createElement('ol');
            edit_submenu.setAttribute('id', 'edit_menu');

       //     var to_be_edited = document.getElementById('enter_choice').parentElement.parentElement;
            var to_be_edited = object_of_interest;
            console.log("to_be_edited", to_be_edited);
            console.log("option", top_menu_options_for(to_be_edited));
            edit_submenu.innerHTML = top_menu_options_for(to_be_edited);
            $("#enter_choice").replaceWith(edit_submenu);
            document.getElementById('choose_current').focus();
        }
        console.log("   Just handled the case of enter_choice");
        return ""

    } else if (theChooseCurrent = document.getElementById("choose_current")) {
        var dataLocation = theChooseCurrent.getAttribute("data-location");  // may be null
        var dataAction = theChooseCurrent.getAttribute("data-action");  // may be null
        var dataEnv = theChooseCurrent.getAttribute("data-env");  // may be null
        var object_of_interest = document.getElementById("edit_menu_holder").parentElement;
        current_level = current_editing["level"];
        current_location = current_editing["location"][current_level];
        current_siblings = current_editing["tree"][current_level];
        console.log("in choose_current", dataLocation, "of", object_of_interest);
        console.log("dataAction ", dataAction);

        if (e.code == "Enter" || e.code == "ArrowRight") {
          e.preventDefault;
          // we have an active menu, and have selected an item
          // there are three main cases, depending on whether there is a data-location attribute,
          // a data-action attribute, or a data-env attribute

// dataLocation
          if (dataLocation) {
            if (dataLocation == "enter") {  // we are moving down into an object

                console.log("current_active_menu_item", current_active_menu_item);
            //    this_menu = document.getElementById('edit_menu_holder');
                var object_to_be_entered = object_of_interest;
                console.log("object_to_be_entered", object_to_be_entered);
            //    this_menu.remove();
                object_to_be_entered.classList.remove("may_select");
                object_to_be_entered.classList.remove("may_leave");
                console.log('next_editable_of(object_to_be_entered, "children")', next_editable_of(object_to_be_entered));
                editableChildren = next_editable_of(object_to_be_entered, "children");
                current_level += 1;
                current_editing["level"] = current_level;
                current_editing["location"][current_level] = 0;
                current_editing["tree"][current_level] = editableChildren;
                console.log("current_editing", current_editing);

        //        editableChildren[0].focus();
                console.log("object_to_be_entered", object_to_be_entered);
                console.log("with some children", editableChildren);
               // put  menu on the item at the top of the block_we_are_reentering
                   // this is a repeat of a Tab case, so consolidate
            console.log("menu place 10");
            console.log("document.activeElement", document.activeElement);

// not right:  data-parent_id is used when we want to change the title or tag
           //      edit_menu_for(document.activeElement, "entering");
                 console.log("menu on", editableChildren[0]);
                 edit_menu_for(editableChildren[0], "entering");

                return ""
            } else {  // dataLoction is beforebegin or afterend
            //    $("#choose_current").parent().addClass("past");
                theChooseCurrent.parentElement.classList.add("past");
                theChooseCurrent.removeAttribute("id");
                theChooseCurrent.classList.add("chosen");

                parent_type = document.getElementById('edit_menu_holder').parentElement.parentElement.tagName.toLowerCase();
                console.log("making a menu for", parent_type);
                var edit_submenu = document.createElement('ol');
                edit_submenu.innerHTML = menu_options_for(parent_type, "base");
        //        edit_submenu.innerHTML = menu_options_for(parent_type, "inner");
                console.log("just inserted inner menu_options_for(" + parent_type + ")", menu_options_for(parent_type, "inner"));
            //    current_active_menu_item.insertAdjacentElement("beforeend", edit_submenu);
                theChooseCurrent.insertAdjacentElement("beforeend", edit_submenu);
                document.getElementById('choose_current').focus();
                console.log("focus is on", $(":focus"));

                console.log("don;t know about dataLocation", dataLocation);
                alert("don;t know about dataLocation" + dataLocation);
                return ""
            }
          }  // dataLocation

// dataAction
          if (dataAction) {
            if (dataAction == "edit") {
               console.log("going to edit", object_of_interest);
               edit_in_place(object_of_interest);
            } else if (dataAction == "change-env-to") {
                    var new_env = current_active_menu_item.getAttribute("data-env");
                    console.log("changing environment to", new_env);
                       // #edit_menu_holder is in span.type, inside .heading, inside article
                    to_be_edited = document.getElementById('edit_menu_holder').parentElement.parentElement.parentElement;
                    console.log("to_be_edited", to_be_edited);
                    var id_of_object = to_be_edited.id;
                    var this_object_source = internalSource[id_of_object];
                    console.log("current envoronemnt", this_object_source);
                    var old_env = internalSource[id_of_object]["ptxtag"];
                    internalSource[id_of_object]["ptxtag"] = new_env;
                    recent_editing_actions.push("changed " + old_env + " to " + new_env + " " + id_of_object);
                    console.log("the change was", "changed " + old_env + " to " + new_env + " " + id_of_object);
                    the_whole_object = html_from_internal_id(id_of_object);
                    console.log("B: the_whole_object", the_whole_object);
                    $("#" + id_of_object).replaceWith(the_whole_object[0]);  // later handle multiple additions
                    edit_menu_for(id_of_object, "entering");
                    return ""

            } else if (dataAction == 'change-env') {
                       // #edit_menu_holder is in span.type, inside .heading, inside article
                    current_env = document.getElementById('edit_menu_holder').parentElement.parentElement.parentElement;
                    current_env_id = current_env.id;
                    current_env_source = internalSource[current_env_id];
                    current_env_name = current_env_source["ptxtag"];
                    console.log("need menu to change", current_env_name, "in", current_env_source);

                    current_active_menu_item.parentElement.classList.add("past");
                    current_active_menu_item.removeAttribute("id");
                    current_active_menu_item.classList.add("chosen");

                    var edit_submenu = document.createElement('ol');
                    edit_submenu.innerHTML = menu_options_for(current_env_name, "change");
                    console.log("just inserted inner menu_options_for(parent_type)", menu_options_for(parent_type, "change"));
                    current_active_menu_item.insertAdjacentElement("beforeend", edit_submenu);
                    document.getElementById('choose_current').focus();
                    console.log("focus is on", $(":focus"));
            } else {
                alert("I don;t know what to do llllllll dataAction", dataAction)
                return
            }
          }  // dataAction
//  qqqqqqq
        } else if ((e.code == "Tab" || e.code == "ArrowDown") && !e.shiftKey) {
            e.preventDefault();
            console.log("hit a Tab (or ArrowDown");
            console.log("prev_char", prev_char.code, "xxxx", prev_char);
            console.log("focus is on", $(":focus"));

//  xxxxxxxxxxx
       if (false && document.getElementById('enter_choice')) {
           this_choice = document.getElementById('enter_choice');
           console.log("there already is an 'enter_choice'");
           var this_menu = document.getElementById("edit_menu_holder");
           console.log("this_menu", this_menu);
           console.log("this_choice", this_choice);
           if (this_choice.getAttribute('data-location') == 'next') {

               $(this_menu).parent().removeClass("may_select");
               console.log("item to get next focus",$("#edit_menu_holder").parent().next('[data-editable="99"]'), "which has length", $("#edit_menu_holder").parent().next('[data-editable="99"]').length);
               if (!$(this_menu).parent().next().length) { //at the end of a block, so new menu goes at end
               //    e.preventDefault();
                   var enclosing_block = $(this_menu).parent().parent()[0];
                   console.log("at the end of", enclosing_block, "with id", enclosing_block.id);
                   this_menu.remove();
            console.log("menu place 5");

                   edit_menu_for(enclosing_block.getAttribute("id"), "leaving");
                   console.log("focus is on",  $(":focus"));
                   console.log("document.getElementById('enter_choice')", document.getElementById('enter_choice'), $(":focus"));
                   return
                }
                else {
                   console.log("moving to next *editable* object A");
                   var this_motion = "entering";
                   var next_to_edit = next_editable_of($(this_menu).parent(), "siblings");
                   console.log("next_to_edit", next_to_edit, "siblings of", $(this_menu).parent());
                   if (!next_to_edit.length) {
                       next_to_edit = next_editable_of($(this_menu).parent(), "previoussiblings");
                   }
                   if (next_to_edit.length) {
                       next_to_edit[0].focus();
                   } else {
                       $(this_menu).parent().parent().focus()
                       this_motion = "leaving";
                   }
 //////                  this_menu.remove()
                   edit_menu_for(document.activeElement, this_motion);
                   return ""
               }
           } else if (this_choice.getAttribute('data-location') == 'stay') { // at end of block, and want to move on
               // remove class from prev sibling, find its next sibling
               console.log("about to leave a block");
               console.log("this_menu", this_menu, "this_menu.previousSibling", document.getElementById('edit_menu_holder').previousSibling);
           //    block_we_are_leaving = document.getElementById('edit_menu_holder').previousSibling;
               console.log("again:  this_menu", this_menu, "this_menu.previousSibling", this_menu.previousSibling);
               console.log("are they the sme?", document.getElementById('edit_menu_holder') == this_menu, document.getElementById('edit_menu_holder'), this_menu);
               block_we_are_leaving = this_menu.previousSibling;
               console.log("here B");
               block_we_are_leaving.classList.remove("may_leave");
               console.log("$(block_we_are_leaving)",$(block_we_are_leaving), "xxxx", $(block_we_are_leaving).next(), "yyyyy", $(block_we_are_leaving).next('[data-editable="99"]'));
               console.log("moving to next object B");
               next_block_to_edit = next_editable_of($(this_menu), "siblings")[0];
               this_menu.remove()
               $(next_block_to_edit).focus();
               console.log("left a block.  focus is now on", $(":focus"));
           } else if (this_choice.getAttribute('data-location') == 'inline') {
               console.log("options for something inline");
               thing_to_edit = document.getElementById("edit_menu_holder").parentElement;
               source_of_thing_to_edit = internalSource[thing_to_edit.parentElement.id]; 
               console.log("thing we are going to edit", thing_to_edit, "which has title", source_of_thing_to_edit["title"]);
               console.log("here C");
               thing_to_edit.classList.remove("may_select");
               this_menu.remove();
               upcoming_blocks = next_editable_of($(thing_to_edit), "siblings");
               if (upcoming_blocks.length) {
                   next_block_to_edit = upcoming_blocks[0];
               console.log("here D");
                   next_block_to_edit.classList.add("may_select");
               } else {
                   next_block_to_edit = thing_to_edit.parentElement;
               console.log("here E");
                   next_block_to_edit.classList.add("may_leave");
               }
               $(next_block_to_edit).focus();
               console.log("next_block_to_edit", next_block_to_edit);
               console.log("here F");
           }  else { alert("Error:  enter_choice without data-location") }
       }
//   xxxxxxxxx
       // and add the option to edit the next object
       if (!document.getElementById('edit_menu_holder') && !document.getElementById('local_menu_holder')) {  // we are not already navigating a menu
            console.log("menu place 6");

           alert("at menu place 6");  // not sure we can ever get here

           edit_menu_for(document.activeElement.id, "entering");        // so create one
    //       $(":focus").addClass("may_select");
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
        if (current_active_menu_item == next_menu_item) { //only one item on menu, so Tab shold move to the next editable item
   // wasteful, clean up
            var editable_objects = next_editable_of(document.getElementById("edit_menu_holder").parentElement.parentElement.parentElement, "children");
            var currently_being_edited = document.getElementById("edit_menu_holder").parentElement;
            console.log("we want to move past", currently_being_edited, "to the next of", editable_objects);
            for (var j=0; j<editable_objects.length; ++j) {
                if (editable_objects[j] ==  currently_being_edited) {
                    current_index = j;
                    console.log("currently editing item", current_index);
                    break
                }
            }
            if (current_index == editable_objects.length - 1) { next_index = 0 }
            else { next_index = current_index + 1 }
            editable_objects[next_index].focus();
            edit_menu_for(document.activeElement, "entering");
        }
        current_active_menu_item.removeAttribute("id");
        console.log("current_active_menu_item", current_active_menu_item, "next_menu_item", next_menu_item);
//        current_active_menu_item.setAttribute("class", "chosen");
        next_menu_item.setAttribute("id", "choose_current");
        console.log("setting focus on",next_menu_item);
        next_menu_item.focus();
      }

    } //  tmp #choose_current

     else if ((e.code == "Tab" && e.shiftKey) || e.code == "ArrowUp") {  // Shift-Tab to prevous object
     // recopied code:  consolidate
        e.preventDefault();
        console.log("just saw a", e.code);
        console.log("focus is on", $(":focus"));
        if (this_choice = document.getElementById('enter_choice')) {
           console.log("there already is an 'enter_choice'");
           // there are two cases:  1) we are at the top of a block (and so may enter it or add near it, or move on)
           //                       2) we are at the bottom (actually, after) a block, and may return to it, or move on
           var this_menu = document.getElementById("edit_menu_holder");
           if (this_choice.getAttribute('data-location') == 'next' || this_choice.getAttribute('data-location') == 'inline') {  // we are at the top of a block
 // need to understand possible use cases for "inline", so this may not be right
               
               $(this_menu).parent().removeClass("may_select");
               console.log("item to get next focus",$("#edit_menu_holder").parent().prev('[data-editable="99"]'), "which has length", $("#edit_menu_holder").parent().next('[data-editable="99"]').length);
               if (!$(this_menu).parent().prev().length) { //at the start of a block, so go up one
               //    e.preventDefault(); 
                   var enclosing_block = $(this_menu).parent().parent()[0]; 
                   console.log("at the end of", enclosing_block, "with id", enclosing_block.id);
                   this_menu.remove();
            console.log("menu place 7");

                   edit_menu_for(enclosing_block.getAttribute("id"), "entering");
                   console.log("focus is on",  $(":focus"));
                   console.log("document.getElementById('enter_choice')", document.getElementById('enter_choice'), $(":focus"));
                   return
                }
                else {
                   console.log("moving to next object C");
     /////////              $(this_menu).parent().prev('[data-editable="99"]').focus();
                   var previous_editable_siblings = next_editable_of($(this_menu).parent(), "previoussiblings");
                   console.log("previous_editable_siblings", previous_editable_siblings);
                   if (previous_editable_siblings.length) {
               //        next_editable_of($(this_menu).parent(), "previoussiblings")[0].focus();
                       previous_editable_siblings[0].focus();
                   } else {
                       $(this_menu).parent().parent().focus()
                   }
             //      $(this_menu).parent().prevAll('.heading > [data-editable="99"], [data-editable="99"]')[0].focus();
                   this_menu.remove()
                   // copied.  consolidate
            console.log("menu place 8");

                   console.log("element with fcous is", $(":focus"), "aka",document.activeElement);
               //    edit_menu_for(document.activeElement.id, "entering");        // so create one
                   edit_menu_for(document.activeElement, "entering");        // so create one
        //           $(":focus").addClass("may_select");
                   console.log("putting focus on", document.getElementById('edit_menu_holder'));
            //       document.getElementById('edit_menu_holder').focus();
                   console.log("element with fcous is", $(":focus"));
                   console.log("are we done tabbing to the next item?");

               }
           } else { // we are at the bottom of a block
               document.getElementById("edit_menu_holder").previousSibling.classList.remove("may_leave");
               document.getElementById("edit_menu_holder").previousSibling.focus();
               document.getElementById("edit_menu_holder").remove()
               edit_menu_for(document.activeElement.id, "entering"); 
           //    alert("Shift-Tab not implemented at the bottom of a block");
           }
       } else {
        // copied from Tab, so consolidate
        console.log("saw an",e.code);
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
  //       console.log("Error:  Shift-Tab not understood when ther eis an active menu");
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
               next_editable_of(block_we_are_reentering, "children")[0].focus();
               this_menu.remove();
               // put  menu on the item at the top of the block_we_are_reentering
                   // this is a repeat of a Tab case, so consolidate
            console.log("menu place 9");

               edit_menu_for(document.activeElement, "entering");
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
           else if (false && document.getElementById('choose_current').hasAttribute("data-action")) {
                var current_active_menu_item = document.getElementById('choose_current');
                var this_action = current_active_menu_item.getAttribute("data-action");
                console.log("               this_action", this_action)
                var to_be_edited = document.getElementById('edit_menu_holder').parentElement;
                if (this_action == "edit") {
                   console.log("going to edit it", to_be_edited);
                   edit_in_place(to_be_edited);
                } else if (this_action == "change-env-to") {
                    var new_env = current_active_menu_item.getAttribute("data-env");
                    console.log("changing environment to", new_env);
                       // #edit_menu_holder is in span.type, inside .heading, inside article
                    to_be_edited = document.getElementById('edit_menu_holder').parentElement.parentElement.parentElement;
                    console.log("to_be_edited", to_be_edited);
                    var id_of_object = to_be_edited.id;
                    var this_object_source = internalSource[id_of_object];  
                    console.log("current envoronemnt", this_object_source);
                    var old_env = internalSource[id_of_object]["ptxtag"];
                    internalSource[id_of_object]["ptxtag"] = new_env;
                    recent_editing_actions.push("changed " + old_env + " to " + new_env + " " + id_of_object);
                    console.log("the change was", "changed " + old_env + " to " + new_env + " " + id_of_object);
                    the_whole_object = html_from_internal_id(id_of_object);
                    console.log("B: the_whole_object", the_whole_object);
                    $("#" + id_of_object).replaceWith(the_whole_object[0]);  // later handle multiple additions
                    edit_menu_for(id_of_object, "entering");
                    return ""
                    
                } else if (this_action == 'change-env') {
                       // #edit_menu_holder is in span.type, inside .heading, inside article
                    current_env = document.getElementById('edit_menu_holder').parentElement.parentElement.parentElement;
                    current_env_id = current_env.id;
                    current_env_source = internalSource[current_env_id];
                    current_env_name = current_env_source["ptxtag"];
                    console.log("need menu to change", current_env_name, "in", current_env_source);

                    current_active_menu_item.parentElement.classList.add("past");
                    current_active_menu_item.removeAttribute("id");
                    current_active_menu_item.classList.add("chosen");

                    var edit_submenu = document.createElement('ol');
                    edit_submenu.innerHTML = menu_options_for(current_env_name, "change");
                    console.log("just inserted inner menu_options_for(parent_type)", menu_options_for(parent_type, "change"));
                    current_active_menu_item.insertAdjacentElement("beforeend", edit_submenu);
                    document.getElementById('choose_current').focus();
                    console.log("focus is on", $(":focus"));

                }
                else { alert("unimplemented action: "+ this_action) }
        }
        // otherwise, see if we just selected a top level menu item about location
        // because that involves checking the parent to see what options are possible
// ppppppppp
          else if (document.getElementById('choose_current').hasAttribute("data-location")) {
            var current_active_menu_item = document.getElementById('choose_current');
            console.log("location infro on",current_active_menu_item);
            if (['beforebegin', 'afterend'].includes(current_active_menu_item.getAttribute("data-location"))) {
            //    $("#choose_current").parent().addClass("past");
                current_active_menu_item.parentElement.classList.add("past");
                current_active_menu_item.removeAttribute("id");
                current_active_menu_item.classList.add("chosen");

                parent_type = document.getElementById('edit_menu_holder').parentElement.parentElement.tagName.toLowerCase();
                console.log("making a menu for", parent_type);
                var edit_submenu = document.createElement('ol');
                edit_submenu.innerHTML = menu_options_for(parent_type, "base");
        //        edit_submenu.innerHTML = menu_options_for(parent_type, "inner");
                console.log("just inserted inner menu_options_for(" + parent_type + ")", menu_options_for(parent_type, "inner"));
                current_active_menu_item.insertAdjacentElement("beforeend", edit_submenu);
                document.getElementById('choose_current').focus();
                console.log("focus is on", $(":focus"));
            } else if (current_active_menu_item.getAttribute("data-location") == "enter") {
                console.log("current_active_menu_item", current_active_menu_item);
                this_menu = document.getElementById('edit_menu_holder');
                var object_to_be_entered = this_menu.parentElement;
                console.log("object_to_be_entered", object_to_be_entered);
                this_menu.remove();
                object_to_be_entered.classList.remove("may_select");
                var object_to_be_entered_type = object_to_be_entered.tagName;
             //   alert("Entering " + object_to_be_edited_type + " not implemented yet");
                console.log('next_editable_of(object_to_be_entered, "children")', next_editable_of(object_to_be_entered));
                console.log("children", next_editable_of(object_to_be_entered, "children")[0]);
                next_editable_of(object_to_be_entered, "children")[0].focus();
                console.log("object_to_be_entered", object_to_be_entered);
                console.log("with some children", $(object_to_be_entered).children('.heading, [data-editable="99"]'));
               // put  menu on the item at the top of the block_we_are_reentering
                   // this is a repeat of a Tab case, so consolidate
            console.log("menu place 10");
            console.log("document.activeElement", document.activeElement);

// not right:  data-parent_id is used when we want to change the title or tag
                  edit_menu_for(document.activeElement, "entering");
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
                next_editable_of(object_we_are_in, "siblings")[0].focus();
            }
        } else { // else check if the selected items leads to a submenu
            console.log("selected a menu item with no action and no location");
            $("#choose_current").parent().addClass("past");
            current_active_menu_item = document.getElementById('choose_current');
            console.log("apparently selected", current_active_menu_item);
            current_active_menu_item.removeAttribute("id");
            current_active_menu_item.setAttribute('class', 'chosen');
            current_active_menu_item_environment = current_active_menu_item.getAttribute('data-env');

            if (current_active_menu_item_environment in inner_menu_for()) {  // object names a collection, so make submenu
                console.log("making a menu for", current_active_menu_item_environment);
                var edit_submenu = document.createElement('ol');
                edit_submenu.innerHTML = menu_options_for(current_active_menu_item_environment, "inner");
     //           console.log("removing id from", current_active_menu_item);
                current_active_menu_item.insertAdjacentElement("beforeend", edit_submenu);
          //      next_menu_item.setAttribute("id", "choose_current");
                document.getElementById('choose_current').focus();
          //      console.log("setting focus AA on",next_menu_item);
            } else {  // we just selected an action, so do it
                      // that probably involves adding something before or after a given object
                var new_object_type = current_active_menu_item.getAttribute("data-env");
                var new_object_type_parent = current_active_menu_item.getAttribute("data-env-parent");
                console.log("making a new", new_object_type, "within", new_object_type_parent);
                if ( (new_object_type_parent in editing_container_for) || (new_object_type in editing_container_for) ) {
                    object_near_new_object = document.getElementById('edit_menu_holder').parentElement;
                    var before_after = $("#edit_menu_holder > #edit_menu > .chosen").attr("data-location");
                    var new_obj = create_object_to_edit(new_object_type, object_near_new_object, before_after);
               //     edit_in_place("", [new_object_type, object_near_new_object, before_after]);
                    edit_in_place(new_obj);
                    object_near_new_object.classList.remove("may_select");
                    document.getElementById('edit_menu_holder').remove();

                 } else if (document.getElementById('actively_editing')) {
                     // need a mini-form for part of the larger form
                     console.log("now make a n-=mini-form");
                     document.getElementById("local_edit_form").remove();
                 } else {
                    alert("don't yet know about " + new_object_type);
                    document.getElementById('edit_menu_holder').parentElement.focus();
            console.log("menu place 11");

                    edit_menu_for(document.activeElement.id, "entering");
                }
            }

        }
    }  else if (e.code == "Escape" || e.code == "ArrowLeft") {
        console.log("processing ESC");
        if (document.getElementById("local_menu_holder")) {  // hack for when the interface gets confused
            document.getElementById("local_menu_holder").remove()
        }
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
       //         document.getElementById('edit_menu_holder').remove();
            console.log("menu place 12");

                edit_menu_for(current_object_to_edit, "entering");
                 // just put the entering option
            }
        } else {  // we are at the top of an object and have not decided to edit it
            current_object_being_edited = document.getElementById('edit_menu_holder').parentNode;
            parent_object_to_edit = current_object_being_edited.parentNode;
            console.log("parent_object_to_edit", parent_object_to_edit);
            current_object_being_edited.classList.remove("may_select");
            console.log("menu place 13");

            edit_menu_for(parent_object_to_edit.id, "entering");
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
            if (input_region == "INPUT") {
                console.log("Enter in an INPUT, so time to save it")
                local_editing_action(e)
            }
            else { // input_region is TEXTAREA
                console.log("about to do local_editing_action", this_char.code, prev_char.code, prev_prev_char.code);
                local_editing_action(e)
            }
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

// retrieve_previous_editing();
console.log("retrieved previous", internalSource);

// make the top level menu
e_tree = current_editing["tree"];
console.log("e_tree", e_tree);
e_level = current_editing["level"];
console.log("e_level", e_level);
e_location = current_editing["location"];
console.log("e_location", e_location);
edit_menu_for(e_tree[e_level], "entering")

