
/* preliminary hacks */


$(".autopermalink > a").attr("tabindex", -1);

//  $("#akX > *").attr("data-editable", 99);
// var editable_objects = ["p", "ol", "ul", "article", "blockquote", "section"];
var editable_objects = [["p", 99], ["ol", 97], ["ul", 96], ["article", 95], ["blockquote", 80], ["section", 66]];
for(var j=0; j < editable_objects.length; ++j) {
    $(editable_objects[j][0]).attr("data-editable", editable_objects[j][1]);
    $(editable_objects[j][0]).attr("tabindex", -1);
}

/* the code */

console.log(" enabling edit");

user_level = "novice";

// we have to keep track of multiple consecutive carriage returns
this_char = "";
prev_char = "";
prev_prev_char = "";

// for resizing and layout changes
// clobal variables so we can adjust them dynamically
move_scale = 1;
magnify_scale = 1;

final_added_object = "";
previous_added_object = "";

// sometimes we have to prevent Tab from changing focus
this_focused_element = "";
prev_focused_element = "";
prev_prev_focused_element = "";

var menu_neutral_background = "#ddb";
var menu_active_background = "#fdd";

var recent_editing_actions = [];  // we unshift to this, so most recent edit is first.
     // currently just a human-readable list
var current_editing_actions = [];
var old_content = {};   // to hold old versions of changed materials

// what will happen with internationalization?
var keyletters = ["KeyA", "KeyB", "KeyC", "KeyD", "KeyE", "KeyF", "KeyG", "KeyH", "KeyI", "KeyJ", "KeyK", "KeyL", "KeyM", "KeyN", "KeyO", "KeyP", "KeyQ", "KeyR", "KeyS", "KeyT", "KeyU", "KeyV", "KeyW", "KeyX", "KeyY", "KeyZ"];

var top_level_id = "hPw";

var current_editing = {
    "level": 0,
    "location": [0],
    "tree": [ [document.getElementById(top_level_id)] ]
}

var movement_location_options = [];
var movement_location = 0;
var first_move = true;  // used when starting to move, because object no longer occupies its original location

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

function spacemath_to_tex(text) {

    thetext = text;

    thetext = thetext.replace(/ d([a-zA-Z])(\s|$)/, " \\,d$1$2");

    return thetext

}

var renamable = {
    "definition-like": ["definition", "conjecture", "axiom", "principle", "heuristic", "hypothesis", "assumption"],
    "theorem-like": ["lemma", "proposition", "theorem", "corollary", "claim", "fact", "identity", "algorithm"],
    "remark-like": ["remark", "warning", "note", "observation", "convention", "insight"],
    "section-like": ["section", "subsection", "exercises"]
}

function object_class_of(tag) {
    console.log("finding object_class_of", tag);
    var known_types = ["theorem-like", "definition-like", "remark-like", "section-like",
                       "example-like", "exercise-like"];

    for (var j=0; j<known_types.length; ++j) {
        if (editing_container_for[known_types[j]].includes(tag)) {
            return known_types[j]
        }

    }

    return "unknown"
}

/* need to distinguish between the list of objects of a type,
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
            ["image/video/sound", "image-like", "v"],
            ["math/chemistry/code", "math-like", "c"],
            ["project/exercise-like", "project-like", "j"],
            ["blockquote/poem/music/etc", "quoted"],
            ["aside-like", "aside-like", "d"],
            ["interactives"],
            ["layout-like"],
            ["section-like"]],
"blockquote": [["paragraph", "p"]],
// "ol": [["list item", "li"]],
"article": [["paragraph", "p"],  //  this is for theorem-like and similar
            ["list or table", "list-like"],
            ["math/chemistry/code", "math-like", "c"],
            ["image/video/sound", "image-like", "v"]],
"li": [["new list item", "li", "i"],
            ["paragraph", "p"],
            ["list or table", "list-like"],
            ["math/chemistry/code", "math-like", "c"],
            ["image/video/sound", "image-like", "v"]],
"p": [["emphasis-like"], ["formula"], ["abbreviation"], ["symbol"], ["ref or link", "ref"]]
}

function inner_menu_for() {

//    console.log("recent_editing_actions", recent_editing_actions, "xx", recent_editing_actions != []);
    var the_past_edits = [];
    if(recent_editing_actions.length) {
         the_past_edits = recent_editing_actions.map(x => [x.join(" ")])}
    else { the_past_edits = [["no chnages yet"]] }

 //   console.log("the_past_edits", the_past_edits);

var the_inner_menu = {
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
// "display-like": [["image"], ["image with caption", "imagecaption", "m"], ["video"], ["video with caption", "videocaption", "d"], ["audio"]],
"image-like": [["image", "bareimage"], ["video"], ["audio"]],
"aside-like": [["aside"], ["historical"], ["biographical"]],
"layout-like": [["side-by-side panels", "sbs"], ["assemblage"], ["biographical aside"], ["titled paragraph", "paragraphs"]],
"sbs": [["2 panels", "sbs2"], ["3 panels", "sbs3"], ["4 panels", "sbs4"]],
"math-like": [["math display", "mathdisplay"], ["chemistry display", "chemistrydisplay"], ["code listing", "code", "l"]],
"quoted": [["blockquote"], ["poem"], ["music"]],
"interactives": [["sage cell", "sagecell"], ["webwork"], ["asymptote"], ["musical score", "musicalscore"]],
"metadata": [["index entries"], ["notation"]],
"emphasis-like": [["emphasis"], ["foreign word", "foreign"], ["book title"], ["article title"], ["inline quote"], ["name of a ship"]],
// "abbreviation": ["ie", "eg", "etc", "et al"],  // i.e., etc., ellipsis, can just be typed.
// next one not used?
// "imagebox": [["make larger"], ["make smaller"], ["shift left"], ["shift right"], ["arrow controls"], ["finished making changes"]],
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
"example-like": ["example", "question", "problem"],
"exercise-like": ["exercise"],
"section-like": ["section", "subsection", "paragraphs", "rq", "exercises"],
"ol": ["item"],
"li": [""],
"list": [""],
"bareimage": [""],
"sbs2": [""],
"sbs3": [""],
"sbs4": [""],
"proof": [""]  //just a guess
}

// each tag has [ptx_tag, [html_start, html_end]]
// Note: end of html_start is missing, to make it easier to add attributes
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
    "creator": ["RETurn to save creator",
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

function make_current_editing_from_id(theid) {

//current_editing keeps track of where we are in the tree.  maybe need a better name?

    console.log("make_current_editing_from_id", theid);
    // the existing current_editing know the top level id
    var top_id = current_editing["tree"][0][0].id;

    // but now we need to start over and go bottom-up
    current_editing = {
            "level": -1,
            "location": [],
            "tree": [ ]
        }

    var current_id = theid;
    var current_element = document.getElementById(current_id);
    var selectable_parent, current_element_siblings, selectable_parent_id;
    var ct=0;
    while (current_id != top_id && ct < 10) {
        ct += 1;
        console.log("ct", ct);
        console.log("looking to match current_element", current_element);
        selectable_parent = current_element.parentElement.closest("[data-editable]");
        current_element_siblings = next_editable_of(selectable_parent, "children");
        current_id = selectable_parent.id;
        console.log("current_id", current_id);
        current_editing["tree"].unshift(current_element_siblings);
        console.log("looking for", current_element, "in", current_element_siblings);
        for (var j=0; j < current_element_siblings.length; ++j) {
            if (current_element == current_element_siblings[j]) {
                current_editing["level"] += 1;
                current_editing["location"].unshift(j);
                console.log("this is item", j);
                break
            } else {
                console.log(current_element == current_element_siblings[j], "aaa", current_element,"zzz", current_element_siblings[j])
            }
        }
        current_element = selectable_parent
    }
    current_editing["level"] += 1;
    current_editing["location"].unshift(0);
    current_editing["tree"].unshift([document.getElementById(top_id)]);

    console.log("built current_editing after", ct, "levels");
    console.log("current_editing[level]", current_editing["level"]);
    console.log("current_editing[location]", current_editing["location"]);
    console.log("current_editing[tree]", current_editing["tree"])
}

function standard_creator_form(object_id) {
    the_object = internalSource[object_id];
    object_type = the_object["ptxtag"];  // need to use that to determin the object_type_name
    object_type_name = object_type;
    the_parent = the_object["parent"];
    the_parent_id = the_parent[0];
    the_parent_component = the_parent[1];

    var creator_form = "<div><b>" + object_type_name + "&nbsp;#N</b>&nbsp;";
    creator_form += '<span id="editing_creator_holder">';
    creator_form += '<input id="actively_editing_creator" class="starting_point_for_editing" data-source_id="' + object_id + '" data-component="' + 'creator' + '" placeholder="Optional creator" type="text"/>';

    creator_form += '&nbsp;<span class="group_description">(' + editing_tip_for("creator") + ')</span>';
    creator_form += '</span>';  // #editing_creator_holder
    creator_form += '</div>';

    return creator_form
}

function menu_options_for(object_id, component_type, level) {
        // this should be a function of the object, not just its tag
        //  p in li vs p child of section, for example
     var menu_for;

     if (!component_type) { component_type = internalSource[object_id]["ptxtag"] }
     console.log("component_tag", component_type);
     if (level == "base") {
         menu_for = base_menu_for
     } else if (level == "move-or-delete") {
         console.log("C0 menu options for", component_type);
         var m_d_options;
         var component_parent = internalSource[object_id]["parent"][0];
         var component_parent_tag = internalSource[component_parent]["ptxtag"];
         if (component_type == "p" && component_parent_tag == "li") {
             m_d_options = [
                 ["move-local-p", "Move these words within this page"],
                 ["move-local-li", "Move this list item within this page"],
                 ["move-global", "Move this another page (not implemented yet)"],
                 ["delete", "Delete"]  // does it matter whether there are other p in this li?
             ];
         } else if(component_type == "p") {
             m_d_options = [
                 ["move-local-p", "Move this text within this page"],
                 ["move-global", "Move to another page (not implemented yet)"],
                 ["delete", "Delete"]
             ];
         } else {
             m_d_options = [
                 ["move-local", "Move within this page"],
                 ["move-global", "Move to another page (not implemented yet)"],
                 ["delete", "Delete"]
             ];
         }
         var this_menu = "";
         for (var i=0; i < m_d_options.length; ++i) {
             this_menu += '<li tabindex="-1" data-action="' + m_d_options[i][0] + '"' // change-env-to" data-env="' + replacement_list[i] + '"';
             if (i==0) { this_menu += ' id="choose_current"'}
             this_menu += '>';
             this_menu += m_d_options[i][1]
             this_menu += '</li>';
         }
         console.log("made this_menu", this_menu);
         return this_menu
     }
     else if (level == "modify") {
         console.log("CZ menu options for", component_type);
         var m_d_options;
         var component_parent = internalSource[object_id]["parent"][0];
         var component_parent_tag = internalSource[component_parent]["ptxtag"];
         if (component_type == "bareimage") {
             m_d_options = [
                 ["modify", "enlarge", "make larger"],
                 ["modify", "shrink", "make smaller"],
                 ["modify", "left", "shift left"],
                 ["modify", "right", "shift right"],
                 ["modify", "arrows", "use arrow keys (not implemented yet)"],
                 ["modify", "done", "done modifying"]
             ];
         } else if (component_type == "sbspanel") {
             m_d_options = [
                 ["modify", "enlarge", "make wider"],
                 ["modify", "shrink", "make narrower"],
                 ["modify", "leftminus", "decrease left margin"],
                 ["modify", "leftplus", "increase left margin"],
                 ["modify", "rightminus", "decrease right margin"],
                 ["modify", "rightplus", "increase right margin"],
                 ["modify", "done", "done modifying"]
             ];
         } else {
             alert("don;t know how to make that menu")
             m_d_options = []
         }
         var this_menu = "";
         for (var i=0; i < m_d_options.length; ++i) {
             this_menu += '<li tabindex="-1" data-action="' + m_d_options[i][0] + '" data-modifier="' + m_d_options[i][1] + '"';
             if (i==0) { this_menu += ' id="choose_current"'}
             this_menu += '>';
             this_menu += m_d_options[i][2]
             this_menu += '</li>';
         }
         console.log("made this_menu", this_menu);
         return this_menu
     }
     else if (level == "change") {
         console.log("C1 menu options for", component_type);
         objectclass = object_class_of(component_type);
         console.log("which has class",objectclass);
         var equivalent_objects = renamable[objectclass].slice();
         var replacement_list = removeItemFromList(equivalent_objects, component_type);
         console.log("equivalent_objects", equivalent_objects);
         var this_menu = "";
         for (var i=0; i < replacement_list.length; ++i) {
             this_menu += '<li tabindex="-1" data-action="change-env-to" data-env="' + replacement_list[i] + '"'; 
             if (i==0) { this_menu += ' id="choose_current"'}
             this_menu += '>';
             this_menu += replacement_list[i];
             this_menu += '</li>';
         }
         console.log("made this_menu", this_menu);
         return this_menu
     } else { menu_for = inner_menu_for() }
     console.log("C2 in menu options for", component_type, "or", object_id);
     console.log("menu_for", menu_for);
     if (component_type in menu_for) {
         component_items = menu_for[component_type]
     } else {
       //  component_items = [["placeholder 1"], ["placeholder 2-like"], ["placeholder 3"], ["placeholder 4"], ["placeholder 5"]];
         // is this a reasbable default for what can go anywhere?
         component_items = [["paragraph", "p"],
            ["list or table", "list-like"],
            ["math/chemistry/code", "math-like", "c"]]
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
         this_menu += '<li tabindex="-1" data-env="' + this_item_label + '"';
         this_menu += ' data-env-parent="' + component_type + '"';
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
    console.log("top menu options for aa", this_obj);

    var this_list = "";

    if (this_obj.classList.contains("heading")) {
        var this_obj_parent = this_obj.parentElement;
        console.log("heading options for bbb", this_obj_parent); 
        var this_obj_parent_id = this_obj_parent.id;
        var this_obj_parent_source = internalSource[this_obj_parent_id];
        var this_obj_environment = this_obj_parent_source["ptxtag"];

        console.log("this_obj_environment", this_obj_environment);
        
        this_list = '<li tabindex="-1" id="choose_current" data-env="p" data-action="edit">Change the creator</li>';
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
            if (editable_children.length) {
                this_list += '<li tabindex="-1" data-env="' + this_object_type + '" data-location="enter">Enter ' + this_obj_environment + '</li>';
            }
        } else if (this_obj.classList.contains("image-box")) {
            this_list = '<li tabindex="-1" id="choose_current" data-env="imagebox" data-action="modify">Modify layout<div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div></li>';
        } else if (this_obj.classList.contains("sbspanel")) {
            this_list = '<li tabindex="-1" id="choose_current" data-env="sbspanel" data-action="modify">Modify layout<div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div></li>';
        } else {
            this_list += '<li tabindex="-1" id="choose_current" data-env="' + this_object_type + '" data-location="enter">Enter ' + this_obj_environment + '</li>';
       }

        this_list += '<li tabindex="-1" data-env="' + this_object_type + '" data-location="beforebegin">Insert before<div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div></li>';
        this_list += '<li tabindex="-1" data-env="' + this_object_type + '" data-location="afterend">Insert after<div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div></li>';
        this_list += '<li tabindex="-1" data-action="move-or-delete">Move or delete<div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div></li>';
        this_list += '<li tabindex="-1" data-env="' + "metaadata" + '">Metadata<div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div></li>';
        this_list += '<li tabindex="-1" data-env="' + "undo" + '">Revert<div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div></li>';
    }
    return this_list
}

function edit_menu_from_current_editing(motion) {
        // obviously we need to think a bit about current_editing and how it is used
    console.log("in edit_menu_from_current_editing, level:", current_editing["level"],"location:", current_editing["location"], "tree:", current_editing["tree"]);
    var object_of_interest = current_editing["tree"][ current_editing["level"] ][ current_editing["location"][ current_editing["level"] ] ];
    console.log("object_of_interest", object_of_interest); 
    edit_menu_for(object_of_interest, motion);
}

function edit_menu_for(this_obj_or_id, motion) {
    console.log("make edit menu", motion, "for", this_obj_or_id);

    // delete the old menu, if it exists
    if (document.getElementById('edit_menu_holder')) {
        var current_menu = document.getElementById('edit_menu_holder');
        console.log("current_menu", current_menu);
        console.log("this_choice", document.getElementById('enter_choice'));
        if (this_choice = document.getElementById('enter_choice')) {
            if (this_choice.getAttribute("data-location") == "stay") {
                current_menu.previousSibling.classList.remove("may_leave")
            } else {
                current_menu.parentElement.classList.remove("may_select");
                current_menu.parentElement.classList.remove("may_enter");
            }
        }
        current_menu.parentElement.classList.remove("may_select");
        current_menu.parentElement.classList.remove("may_enter");
        current_menu.remove();
    }

    if (!this_obj_or_id) {
        console.log("error: empty this_obj_or_id", motion);
        return ""
    } else {
        console.log("this_obj_or_id", this_obj_or_id, "string?", typeof this_obj_or_id === 'string');
        console.log("which has parent", this_obj_or_id.parentElement)
    }

    if (typeof this_obj_or_id === 'string') {
        this_obj = document.getElementById(this_obj_or_id)
    } else {
        this_obj = this_obj_or_id
    }

    if (motion == "entering") {
        menu_location = "afterbegin";
        this_obj.classList.remove("may_leave"); 
        if (next_editable_of(this_obj, "children").length) {
            this_obj.classList.add("may_enter");
        } else {
            this_obj.classList.add("may_select");
        }
        if (this_obj.tagName.toLowerCase() in inline_tags) {
            this_obj.classList.add("inline");
        }
    } else { menu_location = "afterend";
        this_obj.classList.remove("may_select");
        this_obj.classList.remove("may_enter");
        this_obj.classList.add("may_leave"); 
        console.log("added may_leave to", this_obj)
    }  // when motion is 'leaving'

    var edit_menu_holder = document.createElement('div');
    edit_menu_holder.setAttribute('id', 'edit_menu_holder');
    edit_menu_holder.setAttribute('tabindex', '-1');
    console.log("adding menu for", this_obj_or_id, "menu_location", menu_location);
    console.log("which has tag", this_obj.tagName);
    console.log("does", this_obj.classList, "include type", this_obj.classList.contains("type"));

    this_obj.insertAdjacentElement(menu_location, edit_menu_holder);
    console.log("added edit_menu_holder", document.getElementById("edit_menu_holder"));

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
        } else if (this_obj.classList.contains("image-box")) {
            edit_option.innerHTML = "<b>modify</b> this image layout, or add near here?";
        } else if (this_obj.classList.contains("sbspanel")) {
            edit_option.innerHTML = "<b>modify</b> this panel layout, or change panel contents?";
        } else if (this_obj.classList.contains("creator") || this_obj.classList.contains("title")) {
            // need to code this better:  over-writing edit_option
            edit_option = document.createElement('ol');
            edit_option.setAttribute('id', 'edit_menu');
            this_obj_parent_id = this_obj.parentElement.parentElement.id;
            this_obj_environment = internalSource[this_obj_parent_id]["ptxtag"];
            edit_option.innerHTML = '<li id="choose_current" tabindex="-1" data-action="change-title">Change creator</li>';
            edit_option.setAttribute('data-location', 'inline');
        } else {
            if (next_editable_of(this_obj, "children").length) {
                edit_option.innerHTML = "<b>enter</b> this " + internalSource[this_obj.id]["ptxtag"] + ", or add near here?";
            } else {
                edit_option.innerHTML = "<b>edit</b> this paragraph, or add near here?";
            }
            edit_option.setAttribute('data-location', 'next');
        }
    } else {
        edit_option.setAttribute('data-location', 'stay');
        edit_option.innerHTML = "continue editing " + this_obj.tagName;
    }
    console.log("edit_option", edit_option);
    document.getElementById("edit_menu_holder").insertAdjacentElement("afterbegin", edit_option);
    document.getElementById('edit_menu_holder').focus();
}

function local_menu_for(this_obj_id) { 
    console.log("make local edit menu for", this_obj_id);
    var local_menu_holder = document.createElement('div');
    local_menu_holder.setAttribute('id', 'local_menu_holder');
    local_menu_holder.setAttribute('tabindex', '-1');
    console.log("adding local menu for", this_obj_id);
    document.getElementById(this_obj_id).insertAdjacentElement("afterbegin", local_menu_holder);
    
    var enter_option = document.createElement('ol');
    enter_option.setAttribute('id', 'edit_menu');
    
    enter_option.innerHTML = menu_options_for(this_obj_id, "XunusedX", "base");

    document.getElementById("local_menu_holder").insertAdjacentElement("afterbegin", enter_option);
}

/*
let response = await fetch(url);
console.log("status of response",response.status);
*/

function next_editable_of(obj, relationship) {
    var next_to_edit;
    console.log("finding", relationship, "editable of", obj);
    if (relationship == "children") {
        next_to_edit = $(obj).find('> .sidebyside > .sbsrow > [data-editable], > li > [data-editable], > .heading > [data-editable], > [data-editable]')
    } else if (relationship == "outer-block") {  // for example, a direct child of a section
        next_to_edit = $(obj).find(' > [data-editable]')
    } else if (relationship == "inner-block") {  // typically a paragraph
        next_to_edit = $(obj).find('section > [data-editable], [data-editable="99"]')
    } else if (relationship == "li-only") {  // typically a paragraph
        next_to_edit = $(obj).find('li')
    } else {
        console.log("unimplemented next_editable_of")
    }

    console.log("next_to_edit", next_to_edit);
    return next_to_edit
}

function create_object_to_edit(new_tag, new_objects_sibling, relative_placement) {

    console.log("create_object_to_edit", new_tag, new_objects_sibling, relative_placement);
              // first insert a placeholder to edit-in-place
    var new_id = randomstring();
    recent_editing_actions.push(["new", new_tag, new_id]);
        // we won;t need all of these, so re-think when these are created
    var new_content_p_id = randomstring();  // section-like
    var new_statement_p_id = randomstring();  // theorem-like, definition-like, remark-like, example-like, exercise-like
    var edit_placeholder = document.createElement("span");
    edit_placeholder.setAttribute('id', new_id);

    // a sbs is passed as sbsN, where N is the number of columns
    var numcols = 0;
    if (new_tag.startsWith("sbs")) {
        numcols = parseInt(new_tag.slice(-1));
        new_tag = "sbs";
    }
    console.log("new_tag", new_tag, "numcols", numcols);

        // when adding an li, you are actually focused on somethign inside an li
        // but, maybe that distinction shoud be mede before calling create_object_to_edit ?
    if (new_tag == "li") { new_objects_sibling = new_objects_sibling.parentElement }
    new_objects_sibling.insertAdjacentElement(relative_placement, edit_placeholder);

                  // then create the empty internalSource for the new object
    new_source = {"xml:id": new_id, "permid": "", "ptxtag": new_tag, "title": ""}
    if (new_tag == "p") {
        new_source["content"] = "";
    } else if (new_tag == "li") {  // creating an li, which needs one p inside
        var new_p_id = randomstring();
        internalSource[new_p_id] = {"xml:id": new_p_id, "permid": "", "ptxtag": "p", "content": "", "parent": [new_id, "content"]}
        new_source["content"] = "<&>" + new_p_id + "<;>";
        current_editing_actions.push(["new", "li", new_id]);
    } else if (new_tag == "list") {  // creating a list, which needs one item to begin.
                                   // that item is an li contining a p
        var new_li_id = randomstring();
        var new_p_id = randomstring();
        internalSource[new_p_id] = {"xml:id": new_p_id, "permid": "", "ptxtag": "p", "content": "", "parent": [new_li_id, "content"]}
        internalSource[new_li_id] = {"xml:id": new_li_id, "permid": "", "ptxtag": "li", "content": "<&>" + new_p_id + "<;>", "parent": [new_id, "content"] }
        new_source["content"] = "<&>" + new_li_id + "<;>";
        current_editing_actions.push(["new", "li", new_li_id]);

    } else if (new_tag == "sbs") {  // creating an sbs, which contains one sbsrow, which contains several sbspanels
        var new_sbsrow_id = randomstring();
        internalSource[new_sbsrow_id] = {"xml:id": new_sbsrow_id, "permid": "", "ptxtag": "sbsrow",
                 "margin-left": 0, "margin-right": 0, "parent": [new_id, "content"]}

        var col_content = "";
        var col_default_width = [0, 100, 40, 31, 23, 19];
        for (var j=0; j < numcols; ++j) {
            var new_col_id = randomstring();
            col_content += "<&>" + new_col_id + "<;>";
            internalSource[new_col_id] = {"xml:id": new_col_id, "permid": "", "ptxtag": "sbspanel", 
                "width": col_default_width[numcols], "content": "", "parent": [new_sbsrow_id, "content"]}
        }

        internalSource[new_sbsrow_id]["content"] = col_content;
        new_source["content"] = "<&>" + new_sbsrow_id + "<;>";
        current_editing_actions.push(["new", "sbs", new_id]);
        console.log("new sbs", new_source);
    } else if (new_tag == "list") {  // creating a list, which needs one item to begin.
                                   // that item is an li contining a p
        var new_li_id = randomstring();
        var new_p_id = randomstring();
        internalSource[new_p_id] = {"xml:id": new_p_id, "permid": "", "ptxtag": "p", "content": "", "parent": [new_li_id, "content"]}
        internalSource[new_li_id] = {"xml:id": new_li_id, "permid": "", "ptxtag": "li", "content": "<&>" + new_p_id + "<;>", "parent": [new_id, "content"] }
        new_source["content"] = "<&>" + new_li_id + "<;>";
        current_editing_actions.push(["new", "li", new_li_id]);


    } else if (new_tag == "bareimage") {  // creating a bareimage(container), which needs an img
        var new_img_id = randomstring();
        internalSource[new_img_id] = {"xml:id": new_img_id, "permid": "", "ptxtag": "img", "src": "", "parent": [new_id, "content"], "alt": "" }
        new_source["content"] = "<&>" + new_img_id + "<;>";
        new_source["class"] = "image-box";
           // future bug:  these percents are also hard-coded in the div which is iniitally inserted
        new_source["style"] = "width: 50%; margin-right: 25%; margin-left: 25%";
  //      current_editing_actions.push(["new", "li", new_li_id]);
    } else if (editing_container_for["theorem-like"].includes(new_tag) ||
               editing_container_for["definition-like"].includes(new_tag) ||
               editing_container_for["remark-like"].includes(new_tag) ||
               editing_container_for["example-like"].includes(new_tag) ||
               editing_container_for["exercise-like"].includes(new_tag) ) {
        new_source["statement"] = "<&>" + new_statement_p_id + "<;>";
        internalSource[new_statement_p_id] = { "xml:id": new_statement_p_id, "permid": "", ptxtag: "p",
                      content: "", "parent": [new_id, "statement"] }
        if (editing_container_for["theorem-like"].includes(new_tag)) {
            var new_proof_id = randomstring();
            var new_proof_p_id = randomstring();
            new_source["proof"] = "<&>" + new_proof_id + "<;>";
            internalSource[new_proof_id] = { "xml:id": new_proof_id, "permid": "", ptxtag: "proof",
                          content: "<&>" + new_proof_p_id + "<;>", "parent": [new_id, "proof"] }
            internalSource[new_proof_p_id] = { "xml:id": new_proof_p_id, "permid": "", ptxtag: "p",
                          content: "", "parent": [new_proof_id, "content"] }
        } else if (editing_container_for["example-like"].includes(new_tag) ||
               editing_container_for["exercise-like"].includes(new_tag) ) {
            console.log("suggestions (hint, asnwer, solution) not implemented yet")
        }
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
    console.log("    current_editing", current_editing);

// maybe the changes to current_editing is different for lists?

    var object_neighbor = new RegExp('(<&>' + sibling_id + '<;>)');
    var neighbor_with_new = '';
    var current_level = current_editing["level"];
    var current_location = current_editing["location"][current_level];
    console.log("  UUU  current_editing", current_editing["level"], current_editing["location"].length, current_editing["tree"].length, current_editing["tree"][current_editing["level"]])
    if (relative_placement == "beforebegin") {  
        neighbor_with_new = '<&>' + new_id + '<;>\n' + '$1';
    }
    else {
        neighbor_with_new = '$1' + '\n<&>' + new_id + '<;>'
        current_location += 1
        }
    new_arrangement = the_current_arrangement.replace(object_neighbor, neighbor_with_new);
    internalSource[parent_description[0]][parent_description[1]] = new_arrangement;
    if (new_tag == "list") {
        current_editing["level"] += 1;
        current_editing["location"].push(0);
        current_editing["tree"].push([document.getElementById(new_p_id)])
    }  else {
        current_editing["location"][current_level] = current_location;
    }
    console.log("         new_arrangement", new_arrangement);
    console.log("tried to insert", new_id, "next to", sibling_id, "in", the_current_arrangement)
    console.log("    updated current_editing", current_editing);
    console.log("  VVV  current_editing", current_editing["level"], current_editing["location"].length, current_editing["tree"].length, current_editing["tree"][current_editing["level"]])

    return edit_placeholder
}

function edit_in_place(obj, oldornew) {
    // currentlt old_or_new is onlu use as "new" for a new li, so that we know
    // to immediately make a new li to edit

    console.log("in edit in place");
    if (thisID = obj.getAttribute("id")) {
        console.log("will edit in place id", thisID, "which is", obj);
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
      var new_tag = internalSource[thisID]["ptxtag"];
      var new_id = thisID;  // track down why new_id is in the code
      console.log("new_tag is", new_tag, "from", internalSource[thisID]);
      if (new_tag == "p") {
        var this_content_container = document.createElement('div');
        this_content_container.setAttribute('id', "actively_editing");
        this_content_container.setAttribute('data-age', oldornew);
        $("#" + thisID).replaceWith(this_content_container);

 //       var idOfEditContainer = thisID + '_input';
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
        console.log("made edit box for", thisID);
        console.log("which is", document.getElementById(idOfEditText));
        console.log("Whth content CC" + document.getElementById(idOfEditText).innerHTML + "DD");
        console.log("Whth content EE" + document.getElementById(idOfEditText).innerText + "FF");
        console.log("Whth content GG" + document.getElementById(idOfEditText).textContent + "HH");
        this_char = "";
        prev_char = "";

      } else if (new_tag == "bareimage") {
        var this_content_container = document.createElement('div');
        this_content_container.setAttribute('id', "actively_editing");
        this_content_container.setAttribute('data-age', oldornew);
        this_content_container.setAttribute('style', "width:50%; margin-left:auto; margin-right: auto; padding: 2em 3em 3em 3em; background: #fed");
        $("#" + thisID).replaceWith(this_content_container);

 //       var idOfEditContainer = thisID + '_input';
        var idOfEditText = 'editing' + '_input_image';
        var image_editable = document.createElement('div');
        image_editable.setAttribute('contenteditable', 'true');
        image_editable.setAttribute('class', 'image_source');
        image_editable.setAttribute('id', idOfEditText);
        image_editable.setAttribute('style', "background: #fff");
        image_editable.setAttribute('data-source_id', thisID);
        image_editable.setAttribute('data-parent_id', internalSource[thisID]["parent"][0]);
        image_editable.setAttribute('data-parent_component', internalSource[thisID]["parent"][1]);

        document.getElementById('actively_editing').insertAdjacentElement("afterbegin", image_editable);

        var edit_instructions = document.createElement('span');
        edit_instructions.setAttribute('style', "font-size: 90%");
        edit_instructions.innerHTML = "URL of image:"
        document.getElementById('actively_editing').insertAdjacentElement("afterbegin", edit_instructions);

        console.log("setting", $('#' + idOfEditText), "to have contents", internalSource[thisID]["content"]);
        the_contents = internalSource[thisID]["content"];
        the_contents = expand_condensed_source_html(the_contents, "edit");
        $('#' + idOfEditText).html(the_contents);
        document.getElementById(idOfEditText).focus();
        console.log("made edit box for", thisID);
        console.log("which is", document.getElementById(idOfEditText));
        console.log("Whth content CC" + document.getElementById(idOfEditText).innerHTML + "DD");
        console.log("Whth content EE" + document.getElementById(idOfEditText).innerText + "FF");
        console.log("Whth content GG" + document.getElementById(idOfEditText).textContent + "HH");
        this_char = "";
        prev_char = "";

      } else if (new_tag == "sbs") {
        var this_content_container = document.createElement('div');
        this_content_container.setAttribute('class', "sidebyside");
        this_content_container.setAttribute('id', thisID);
        $("#" + thisID).replaceWith(this_content_container);

        console.log('internalSource[thisID]', internalSource[thisID]);
        var idOfSBSRow = internalSource[thisID]["content"];  // sbs only contains an sbsrow
        console.log('idOfSBSRow', idOfSBSRow);
        idOfSBSRow = idOfSBSRow.replace(/<.>/g, "");
        console.log('idOfSBSRow', idOfSBSRow);
        var this_sbsrow = document.createElement('div');
        this_sbsrow.setAttribute('class', 'sbsrow');
        this_sbsrow.setAttribute('id', idOfSBSRow);
        this_sbsrow.setAttribute('style', "margin-left: 5%; margin-right: 5%;");

        var panelwidths = [[25, 50], [25, 25, 40], [20, 20, 20, 30]];
        var idsOfSBSPanel = internalSource[idOfSBSRow]["content"]
        idsOfSBSPanel = idsOfSBSPanel.replace(/^ *<&>/, '');
        idsOfSBSPanel = idsOfSBSPanel.replace(/<;> *$/, '');
        console.log('a idsOfSBSPanel', idsOfSBSPanel);
        idsOfSBSPanel = idsOfSBSPanel.replace(/> +</g, '><');
        console.log('b idsOfSBSPanel', idsOfSBSPanel);
        var idsOfSBSPanelList = idsOfSBSPanel.split("<;><&>");
        console.log('c idsOfSBSPanel', idsOfSBSPanelList);
        var these_panelwidths = panelwidths[idsOfSBSPanelList.length - 2];
        var these_panels = '';
        for (var j=0; j < idsOfSBSPanelList.length; ++j) {
            these_panels += '<div class="sbspanel top" id="' + idsOfSBSPanelList[j] + '" data-editable="90" style="width:' + these_panelwidths[j] + '%; background-color:#ddf">aasda as' + j + ' a abb</div>';
        }
        this_sbsrow.innerHTML = these_panels;
  //      document.getElementById('actively_editing').insertAdjacentElement("afterbegin", this_sbsrow);
        document.getElementById(thisID).insertAdjacentElement("afterbegin", this_sbsrow);

        console.log("made sbs", thisID);

      } else if (new_tag == "li") {  // this is confusing, because really we are editing the p in the li
        var this_new_li = document.createElement('li');
        this_new_li.setAttribute('id', thisID);
        $("#" + thisID).replaceWith(this_new_li);

        var this_content_container = document.createElement('div');
        this_content_container.setAttribute('id', "actively_editing");
        document.getElementById(thisID).insertAdjacentElement("afterbegin", this_content_container);

        console.log("NOT: inserted li, with #actively_editing inside it");
 //       var idOfEditContainer = thisID + '_input';
        var idOfEditText = 'editing' + '_input_text';
        var paragraph_editable = document.createElement('div');
        paragraph_editable.setAttribute('contenteditable', 'true');
        paragraph_editable.setAttribute('class', 'eeee text_source paragraph_input');
        paragraph_editable.setAttribute('id', idOfEditText);
        paragraph_editable.setAttribute('data-age', oldornew);
        // need the content of the new li, for the p id
        var id_of_p = internalSource[thisID]["content"];
        id_of_p = id_of_p.replace(/<.>/g, "");
        console.log("id_of_p", id_of_p);
        paragraph_editable.setAttribute('data-source_id', id_of_p);
        paragraph_editable.setAttribute('data-parent_id', thisID);  // this li
        paragraph_editable.setAttribute('data-parent_component', "content");  // the p is in the content of the li
  
        document.getElementById('actively_editing').insertAdjacentElement("afterbegin", paragraph_editable);
  
        console.log("setting", $('#' + idOfEditText), "to have contents", internalSource[thisID]["content"]);
        the_contents = internalSource[thisID]["content"]; 
        the_contents = expand_condensed_source_html(the_contents, "edit");
        $('#' + idOfEditText).html(the_contents);
        document.getElementById(idOfEditText).focus();
        console.log("made edit box for", thisID);
        this_char = "";
        prev_char = "";

     } else if (new_tag == "list") {
        console.log("list edit in place", obj)
        var this_new_list = document.createElement('ol');   // later distinguish between ol and ul
        this_new_list.setAttribute('id', thisID);
        this_new_list.setAttribute('data-editable', 97);
        this_new_list.setAttribute('tabindex', -1);
        $("#" + thisID).replaceWith(this_new_list);

        var id_of_li = internalSource[thisID]["content"];
        id_of_li = id_of_li.replace(/<.>/g, "");
        console.log("id_of_li", id_of_li);
        var this_new_li = document.createElement('li');
        this_new_li.setAttribute('id', id_of_li);
        document.getElementById(thisID).insertAdjacentElement("afterbegin", this_new_li);




        var this_content_container = document.createElement('div');
        this_content_container.setAttribute('id', "actively_editing");
        document.getElementById(id_of_li).insertAdjacentElement("afterbegin", this_content_container);

        console.log(": inserted li, with #actively_editing inside it");
 //       var idOfEditContainer = thisID + '_input';
        var idOfEditText = 'editing' + '_input_text';
        var paragraph_editable = document.createElement('div');
        paragraph_editable.setAttribute('contenteditable', 'true');
        paragraph_editable.setAttribute('class', 'eeee text_source paragraph_input');
        paragraph_editable.setAttribute('id', idOfEditText);
        paragraph_editable.setAttribute('data-age', oldornew);
        // need the content of the new li, for the p id
        var id_of_p = internalSource[id_of_li]["content"];
        id_of_p = id_of_p.replace(/<.>/g, "");
        console.log("id_of_p", id_of_p);
        paragraph_editable.setAttribute('data-source_id', id_of_p);
        paragraph_editable.setAttribute('data-parent_id', thisID);  // this li
        paragraph_editable.setAttribute('data-parent_component', "content");  // the p is in the content of the li

        document.getElementById('actively_editing').insertAdjacentElement("afterbegin", paragraph_editable);

        console.log("setting", $('#' + idOfEditText), "to have contents", internalSource[thisID]["content"]);
        the_contents = internalSource[id_of_p]["content"];
        the_contents = expand_condensed_source_html(the_contents, "edit");
        $('#' + idOfEditText).html(the_contents);
        document.getElementById(idOfEditText).focus();
        console.log("made edit box for", thisID);
        console.log("actually, made edit box for", id_of_p);
        this_char = "";
        prev_char = "";

        make_current_editing_from_id("actively_editing");

      } else if (editing_container_for["definition-like"].includes(new_tag) ||
                editing_container_for["theorem-like"].includes(new_tag) ||
                editing_container_for["remark-like"].includes(new_tag) ||
                editing_container_for["exercise-like"].includes(new_tag) ||
                editing_container_for["example-like"].includes(new_tag) ||
                editing_container_for["section-like"].includes(new_tag)) {
// only good for creating a new theorem or definition, not editing in place
// think about thaat use case:  once it exists, do we ever edit the theorem as a unit?

        console.log("edit in place", obj);
        var objecttype = object_class_of(new_tag);
        var this_content_container = document.createElement('div');
        this_content_container.setAttribute('id', "actively_editing");
        this_content_container.setAttribute('data-age', oldornew);
        this_content_container.setAttribute('data-objecttype', objecttype);

        var creator = standard_creator_form(new_id);

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
        console.log("made the statement");

        var proof = "";
        var suggestions = "";
        if (editing_container_for["theorem-like"].includes(new_tag)) {
            var proof_container_start = '<div class="editing_proof">';
            var proof_container_end = '</div>';
            var proofinstructions = '<span class="group_description">optional proof (paragraphs, images, lists, etc)</span>';
            var new_proof_id = internalSource[new_id]["proof"];
            console.log("new_proof_id", new_proof_p_id);
            new_proof_id = new_proof_id.replace(/<.>/g, "");
            var new_proof_p_id = internalSource[new_proof_id]["content"];
            console.log("new_proof_p_id", new_proof_p_id);
            new_proof_p_id = new_proof_p_id.replace(/<.>/g, "");
            var proofeditingregion = '<div id="actively_editing_proof" class="paragraph_input" contenteditable="true" style="width:98%;min-height:6em;" placeholder="first paragraph of optional proof"  data-source_id="' + new_proof_p_id + '" data-parent_id="' + new_id + '" data-parent_component="proof"></div>';

            proof = proof_container_start + editingregion_container_start;
            proof += proofinstructions;
            proof += proofeditingregion;
            proof += editingregion_container_end + proof_container_end;
        } else if (editing_container_for["example-like"].includes(new_tag) ||
                   editing_container_for["exercise-like"].includes(new_tag)) {
            console.log("suggesitons not fully implemented yet");
            var suggestions_container_start = '<div class="editing_suggestions">';
            var suggestions_container_end = '</div>';
            var suggestionsinstructions = '<span class="group_description">optional suggestions (hint, answer, solution)</span>';
            var suggestionseditingregion = '<div id="actively_editing_suggestions" class="suggestions_input" contenteditable="true" style="width:98%;min-height:6em;" data-source_id="' + "XXXXXXXX" + '" data-parent_id="' + "YYYYYYY" + '" data-parent_component="suggestions"></div>';

            suggestions = suggestions_container_start + editingregion_container_start;
            suggestions += suggestionsinstructions;
            suggestions += suggestionseditingregion;
            suggestions += editingregion_container_end + suggestions_container_end;
        }

        this_content_container.innerHTML = creator + statement + (proof || suggestions);

        $("#" + thisID).replaceWith(this_content_container);
        $("#actively_editing_creator").focus();
      } 
        else {
          console.log("I do not know how to edit", new_tag)
     }
   } else {
        console.log("Error: edit in place of object that is not already known", obj);
        console.log("What is known:", internalSource)
     }
}

function modify_by_id_img(theid, modifier) {

    var the_sizes = internalSource[theid]["style"];

//modify: enlarge, shrink, left, right, ??? done

// make the data structure better, then delete this comment
// currently style looks like "width: 66%; margin-right: 17%; margin-left: 17%"
    the_sizes = the_sizes.replace(/( |%)/g, "");
    the_sizes = the_sizes.replace(/;/g, ":");
    console.log("the_sizes, modified", the_sizes);
    console.log("the_sizes, split", the_sizes.split(":"));
    var [,width, , marginright, , marginleft] = the_sizes.split(":");
    console.log('width, , marginright, , marginleft', width, "mr", marginright, "ml",  marginleft);
    width = parseInt(width);
    marginright = parseInt(marginright);
    marginleft = parseInt(marginleft);

    var scale_direction = 1;
    var moving_direction = 1;
    if (modifier == "shrink") { scale_direction = -1 }
    else if (modifier == "left") { moving_direction = -1 }
    if ("enlarge shrink".includes(modifier)) {
        if ((width >= 100 && scale_direction == 1) || (width <= 0 && scale_direction == -1)) {
            console.log("can't go above 100 or below 0");
            return
        } else {
            width += 2*scale_direction*magnify_scale;
        }
        if (marginleft > 0 && marginright > 0) {
          marginleft += -1*scale_direction*magnify_scale;
          marginright += -1*scale_direction*magnify_scale;
        } else if (marginleft > 0) {
            marginleft += -2*scale_direction*magnify_scale;
        } else if (marginright > 0) {
            marginright += -2*scale_direction*magnify_scale;
        } else if (scale_direction < 0) {  // applies when we shrink a 100 width image
          marginleft += -1*scale_direction*magnify_scale;
          marginright += -1*scale_direction*magnify_scale;
        } else {
            // do nothing:  this is a placeholder which is reached when both margins are 0
            console.log("already have no margins, width is", width);
        }
    } else if ("left right".includes(modifier)) {
        console.log("marginleft*moving_direction", marginleft*moving_direction, "marginright*moving_direction", marginright*moving_direction);
        if ((marginleft > 0 && marginright > 0) || (marginright*moving_direction > 0) || (marginleft*moving_direction < 0)) {
            marginleft += moving_direction*move_scale;
            marginright += -1*moving_direction*move_scale;
//        } else if (marginright*moving_direction > 0) {
//            marginright += -1*moving_direction*move_scale;
//        } else if (marginleft*moving_direction < 0) {
//            marginleft += moving_direction*move_scale;
        } else { 
            // do nothing:  this is a placeholder which is reached when both margins are 0
            // we choose to prioritize scale, so a 100% image cannot be shifted
            console.log("already at 100%, width is", width);
        }
    }

    var the_new_sizes = "width: " + width + "%;";
    the_new_sizes += "margin-right: " + marginright + "%;";
    the_new_sizes += "margin-left: " + marginleft + "%;";

    internalSource[theid]["style"] = the_new_sizes;

    document.getElementById(theid).setAttribute("style", the_new_sizes);
}

function modify_by_id_sbs(theid, modifier) {

    var this_sbs_source = internalSource[theid];
    var this_width = this_sbs_source["width"];
    var this_sbsrow_source = internalSource[this_sbs_source["parent"][0]];
    console.log("this_sbsrow_source", this_sbsrow_source);
    var marginleft = this_sbsrow_source["margin-left"];
    var marginright = this_sbsrow_source["margin-right"];
    var these_siblings = this_sbsrow_source["content"];
    these_siblings = these_siblings.replace(/^ *<&> */, "");
    these_siblings = these_siblings.replace(/ *<;> *$/, "");
    these_siblings = these_siblings.replace(/> *</, "><");
    console.log("these_siblings", these_siblings);
    these_siblings_list = these_siblings.split("<;><&>");
    var this_panel_index = these_siblings_list.indexOf(theid);
    console.log("this panel", theid, "is", this_panel_index, "within", these_siblings_list);
    these_panel_widths = [];
    total_width = 0;
    for(var j=0; j < these_siblings_list.length; ++j) {
        var t_wid = internalSource[these_siblings_list[j]]["width"];
        console.log("adding width", t_wid);
        total_width += t_wid;
        these_panel_widths.push(t_wid);
    }
    if (this_width != these_panel_widths[this_panel_index]) {
        console.log("error: width", this_width, "not on list", these_panel_widths)
    } else {
        console.log("width", this_width, "on list", these_panel_widths)
    }
    this_width = parseInt(this_width);
    marginright = parseInt(marginright);
    marginleft = parseInt(marginleft);

    console.log("occ", marginleft, "u", total_width, "pi", marginright, "ed", marginleft + total_width + marginright)
    var remaining_space = 100 - (marginleft + total_width + marginright);
    console.log("remaining_space", remaining_space);

//modify: enlarge, shrink, left, right, ??? done

// make the data structure better, then delete this comment
// currently style looks like "width: 66%; margin-right: 17%; margin-left: 17%"
    console.log('width, , marginright, , marginleft', this_width, "mr", marginright, "ml",  marginleft);

    var scale_direction = 1;
    var moving_direction = 1;
    if (modifier == "shrink") { scale_direction = -1 }
    else if (modifier == "left") { moving_direction = -1 }
    if ("enlarge shrink".includes(modifier)) {
        if ((this_width >= 100 && scale_direction == 1) || (this_width <= 0 && scale_direction == -1)) {
            console.log("can't go above 100 or below 0");
            return
        } else {
            this_width += 2*scale_direction*magnify_scale;
        }
        if (marginleft > 0 && marginright > 0) {
          marginleft += -1*scale_direction*magnify_scale;
          marginright += -1*scale_direction*magnify_scale;
        } else if (marginleft > 0) {
            marginleft += -2*scale_direction*magnify_scale;
        } else if (marginright > 0) {
            marginright += -2*scale_direction*magnify_scale;
        } else if (scale_direction < 0) {  // applies when we shrink a 100 width image
          marginleft += -1*scale_direction*magnify_scale;
          marginright += -1*scale_direction*magnify_scale;
        } else {
            // do nothing:  this is a placeholder which is reached when both margins are 0
            console.log("already have no margins, width is", this_width);
        }
    } else if ("left right".includes(modifier)) {
        console.log("marginleft*moving_direction", marginleft*moving_direction, "marginright*moving_direction", marginright*moving_direction);
        if ((marginleft > 0 && marginright > 0) || (marginright*moving_direction > 0) || (marginleft*moving_direction < 0)) {
            marginleft += moving_direction*move_scale;
            marginright += -1*moving_direction*move_scale;
//        } else if (marginright*moving_direction > 0) {
//            marginright += -1*moving_direction*move_scale;
//        } else if (marginleft*moving_direction < 0) {
//            marginleft += moving_direction*move_scale;
        } else { 
            // do nothing:  this is a placeholder which is reached when both margins are 0
            // we choose to prioritize scale, so a 100% image cannot be shifted
            console.log("already at 100%, width is", this_width);
        }
    }

    var the_new_sizes = "width: " + this_width + "%;";
    the_new_sizes += "margin-right: " + marginright + "%;";
    the_new_sizes += "margin-left: " + marginleft + "%;";

    internalSource[theid]["style"] = the_new_sizes;

    document.getElementById(theid).setAttribute("style", the_new_sizes);
}

function move_by_id_local(theid, thehandleid) {
    // when moving an object within a page, we create a phantomobject that is manipulated
    // the actual movement is handled by move_object(e)

    first_move = true;

    document.getElementById("edit_menu_holder").remove()
    document.getElementById(theid).classList.remove("may_select");

    moved_content = internalSource[theid];
    moved_content_tag = moved_content["ptxtag"];
    current_editing_actions.push(["moved", moved_content_tag, theid]);
    moved_parent_and_location = moved_content["parent"];
    console.log("moving", theid);
    console.log("moved_parent_and_location", moved_parent_and_location);
  // code duplicated elsewhere
    var where_it_was = internalSource[moved_parent_and_location[0]][ moved_parent_and_location[1] ];
    console.log("where_it_was", where_it_was);
    var object_in_parent = '<&>' + theid + '<;>';
    var where_it_is = where_it_was.replace(object_in_parent, "");
    console.log("where_it_is ZZ" + where_it_is + "EE");
    internalSource[moved_parent_and_location[0]][ moved_parent_and_location[1] ] = where_it_is;

    // but first, remember the initial location of the object

    moving_object = document.getElementById(theid);
    console.log("moving", moving_object, "within this page");
    console.log("moving_id", theid);
    console.log("current_editing[tree][0]", current_editing["tree"][0]);
    if (moved_content_tag == "li") {
        movement_location_neighbors = next_editable_of(current_editing["tree"][0][0], "li-only");
    } else if (moved_content_tag == "p") {
        movement_location_neighbors = next_editable_of(current_editing["tree"][0][0], "inner-block");
    } else {
        movement_location_neighbors = next_editable_of(current_editing["tree"][0][0], "outer-block");
    }
    console.log("movement_location_neighbors", movement_location_neighbors);
    var foundit = false;
    var movement_location_tmp = 0;
    for (var j=0; j < movement_location_neighbors.length; ++j) {
        if (movement_location_neighbors[j] == moving_object) {
            movement_location_tmp = j;
                // delete the one which is being moved, because
                // we are making a list of slots to place it, and its slot will still be there
                // isn't there a better way to delete one item from a list?
            movement_location_neighbors.splice(j, 1);
            foundit = true;
            break;
        }
    }

    if (!foundit) { console.log("serious error:  trying to move an object that is not movable", theid) }

    console.log("movement_location_tmp", movement_location_tmp);
    // a paragraph by itself in an item or a statement can have a new paragraph before or after it
    movement_location_options = [[movement_location_neighbors[0], "beforebegin"],
                                 [movement_location_neighbors[0], "afterend"]];
    movement_location = 0;
    var movement_location_ct = 1;
    for (var j=1; j < movement_location_neighbors.length; ++j) {
        if (movement_location_tmp == j) { movement_location = movement_location_ct }
        movement_location_ct += 1;
        if (movement_location_neighbors[j-1].parentElement == movement_location_neighbors[j].parentElement) {
            movement_location_options.push([movement_location_neighbors[j], "afterend"])
        } else {
            movement_location_ct += 1;
            movement_location_options.push([movement_location_neighbors[j], "beforebegin"])
            movement_location_options.push([movement_location_neighbors[j], "afterend"])
        }
    }
    console.log("movement_location_ct", movement_location_ct);
    console.log("movement_location", movement_location);

    console.log("made", movement_location_options.length, "movement_location_options", movement_location_options);
    console.log("from", movement_location_neighbors.length, "movement_location_neighbors", movement_location_neighbors);
 
    var the_phantomobject = document.createElement('div');
    the_phantomobject.setAttribute("id", "phantomobject");
    the_phantomobject.setAttribute("data-moving_id", theid);
    the_phantomobject.setAttribute("data-handle_id", thehandleid);
    the_phantomobject.setAttribute("class", "move");
    the_phantomobject.setAttribute("tabindex", "-1");
    var these_instructions = '<div class="movearrow"><span class="arrow">&uarr;</span><p class="up">"shift-tab", or "up arrow", to move up</p></div>';
    these_instructions += '<div class="movearrow"><p class="done">"return" or "escape" to set in place </p></div>';
    these_instructions += '<div class="movearrow"><span class="arrow">&darr;</span><p class="down">"tab" or "down arrow" to move down</p></div>';
    the_phantomobject.innerHTML = these_instructions;
    //  if we are moving a p which has parent li, and it is the only p there, then delete the parent li
    //  note:  this will be wrong if there is other non-p siblings inside the li
    var moving_object_replace = moving_object;
    if (moved_content_tag == "p" && internalSource[moved_parent_and_location[0]]["ptxtag"] == "li") {
        // check if that p is the only thing inside the li (so the li is empty when we move the p), and if so,
        // remove that li from internalSource and also the HTML, and the reverence to it in internalSource
        if (moving_object.parentElement.getElementsByTagName("p").length == 1) {
            moving_object_replace = moving_object.parentElement
            var now_empty_li_id = moved_parent_and_location[0];
            console.log("list item now empty:", now_empty_li_id);
            var now_empty_li_parent_and_location = internalSource[now_empty_li_id]["parent"];
            var where_it_was = internalSource[now_empty_li_parent_and_location[0]][ now_empty_li_parent_and_location[1] ];
            var object_in_parent = '<&>' + now_empty_li_id + '<;>';
            var where_it_is = where_it_was.replace(object_in_parent, "");
            delete internalSource[now_empty_li_id];
            console.log("where_it_is II" + where_it_is + "OO");
            internalSource[now_empty_li_parent_and_location[0]][ now_empty_li_parent_and_location[1] ] = where_it_is;
        }
    }
    moving_object_replace.replaceWith(the_phantomobject)
    document.getElementById("phantomobject").focus();
}

function move_object(e) {
                // we have alread set movement_location_options and movement_location
    console.log("movement_location",movement_location);
    if ((e.code == "Tab" && e.shiftKey) || e.code == "ArrowUp") {  // Shift-Tab up the page
        e.preventDefault();
        if (movement_location == 0) {
            alert("can't move past the top")
        } else {
            if (first_move) { first_move = false; }
            movement_location -= 1
        }
    } else if ((e.code == "Tab" || e.code == "ArrowDown") && !e.shiftKey) {
        e.preventDefault();
        if (first_move) { first_move = false; console.log("did first move") }
        if (movement_location == movement_location_options.length - 1) {
            alert("can't move past the bottom")
        } else {
            movement_location += 1
        }
    } else if (e.code == "Escape" || e.code == "Enter" || e.code == "ArrowRight") {
        e.preventDefault();
        console.log(" decided where to put moving_object", moving_object);
        var id_of_moving_object = document.getElementById('phantomobject').getAttribute("data-moving_id");
        var handle_of_moving_object = document.getElementById('phantomobject').getAttribute("data-handle_id");
        document.getElementById('phantomobject').remove();
        var new_anchor_and_position = movement_location_options[movement_location]
        console.log("new_location_anchor",new_anchor_and_position);
        new_anchor_and_position[0].insertAdjacentElement(new_anchor_and_position[1], moving_object);

        // the html appears to be updated, but we still need to update both the internal source:
        var new_neighbor_id = new_anchor_and_position[0].id;
        console.log("new_neighbor_id", new_neighbor_id);
        var new_neighbor_rel_pos = new_anchor_and_position[1];
        var [new_neighbor_parent, new_neighbor_location] = internalSource[new_neighbor_id]["parent"];
        var new_neighbor_in_context = internalSource[new_neighbor_parent][new_neighbor_location];
        var neighbor_tag = '<&>' + new_neighbor_id + '<;>';
        var moving_object_tag = '<&>' + new_neighbor_id + '<;>';
        if (new_neighbor_rel_pos == "beforebegin") {
            new_neighbor_in_context.replace(neighbor_tag, moving_object_tag + "\n" + neighbor_tag)
        } else {
            new_neighbor_in_context.replace(neighbor_tag, neighbor_tag + "\n" + moving_object_tag)
        }
        internalSource[new_neighbor_parent][new_neighbor_location] = new_neighbor_in_context;
        internalSource[id_of_moving_object]["parent"] = [new_neighbor_parent, new_neighbor_location];


        // and the navigation information
        make_current_editing_from_id(handle_of_moving_object);

        var most_recent_edit = current_editing_actions.pop();
        recent_editing_actions.unshift(most_recent_edit);

        edit_menu_from_current_editing("entering");
        return

    } else {
        console.log("don't know how to move with", e.code)
    }

    console.log("now movement_location", movement_location);
    var the_phantomobject = document.getElementById('phantomobject');
    movement_location_options[movement_location][0].insertAdjacentElement(movement_location_options[movement_location][1], the_phantomobject);
    document.getElementById("phantomobject").focus();
}

function delete_by_id(theid, thereason) {
    // reasons to delete something:  author wants it deleted, it is empty, ...
        // first delete the specific object
    console.log("deleting by theid", theid, "with content", internalSource[theid]);
    var deleted_content = internalSource[theid];
    var parent_and_location = deleted_content["parent"];
    delete internalSource[theid];
    console.log("deleted", theid, "so", theid in internalSource, "now", internalSource);
        // and save what was deleted
    if (theid in old_content) {
        old_content[theid].push(deleted_content)
    } else {
        old_content[theid] = [deleted_content]
    }
    if (thereason != "newempty") {
        current_editing_actions.push(["deleted ", deleted_content["ptxtag"], theid]);
    }
        // update the parent of the object
    var current_level = current_editing["level"];
    var where_it_was = internalSource[parent_and_location[0]][ parent_and_location[1] ];
    var object_in_parent = '<&>' + theid + '<;>';
    var where_it_is = where_it_was.replace(object_in_parent, "");
    console.log("where_it_is ZZ" + where_it_is + "EE");
    internalSource[parent_and_location[0]][ parent_and_location[1] ] = where_it_is;
        // if the parent is empty, delete it
    if (!(where_it_is.trim()) && (parent_and_location[1] == "content" || parent_and_location[1] == "statement")) {
        document.getElementById(theid).removeAttribute("data-editable");  // so it is invisible to next-editable-of as we delete its parent
        if (internalSource[parent_and_location[0]][ "ptxtag" ] == "li") {
            console.log("not going up a level, because it is a list element")
        } else {
            current_editing["level"] -= 1;
        }
        delete_by_id(parent_and_location[0], thereason)
    } else {  // else, because the parent is going to be deleted, so no need to delete the child
        // delete from the html
        if (thereason == "empty" || thereason == "newempty") {
            document.getElementById(theid).remove()
        } else {
            document.getElementById("edit_menu_holder").remove()
            document.getElementById(theid).setAttribute("id", "deleting");
            document.getElementById("deleting").removeAttribute("data-editable");  // so it is invisible to next-editable-of
            setTimeout(() => {  document.getElementById("deleting").remove(); }, 600);
        }

  //  ERROR:  if deleting that element leaves an empty content or statement, then delete the parent
  //  (in HTML and internalSource)

        // update current_editing
        var editing_parent = current_editing["tree"][ current_level - 1 ][ current_editing["location"][ current_level - 1 ] ];
        current_editing["tree"][current_editing["level"]] = next_editable_of(editing_parent, "children");
        if (current_editing["location"] >= current_editing["tree"][ current_level ].length ) {
            current_editing["location"] = current_editing["tree"][ current_level ].length - 1
        }
        edit_menu_from_current_editing("entering");
    }
}

var internalSource = {  // currently the key is the HTML id
   "hPw": {"xml:id": "", "permid": "hPw", "ptxtag": "section", "title": "What is Discrete Mathematics?",
           "content": "<&>akX<;>\n<&>UvL<;>\n<&>ACU<;>\n<&>gKd<;>\n<&>MRm<;>\n<&>udO<;>\n<&>sYv<;>\n<&>ZfE<;>"},
   "gKd": {"xml:id": "", "permid": "", "ptxtag": "p", "title": "", "parent": ["hPw","content"],
           "content": "Discrete math could still ask about the range of a function, but the set would not be an interval. Consider the function which gives the number of children of each person reading this. What is the range? I'm guessing it is something like \(\{0, 1, 2, 3\}\text{.}\) Maybe 4 is in there too. But certainly there is nobody reading this that has 1.32419 children. This output set <em class='emphasis'>is</em> discrete because the elements are separate. The inputs to the function also form a discrete set because each input is an individual person."},
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
   "eUQ": {"xml:id": "", "permid": "eUQ", "ptxtag": "li", "parent": ["ooC","content"],
           "content": "<&>jEJ<;>"},
   "jEJ": {"xml:id": "", "permid": "jEJ", "ptxtag": "p", "parent": ["eUQ","content"],
           "content": "Back in the days of yore, five small towns decided they wanted to build roads directly connecting each pair of towns. While the towns had plenty of money to build roads as long and as winding as they wished, it was very important that the roads not intersect with each other (as stop signs had not yet been invented). Also, tunnels and bridges were not allowed. Is it possible for each of these towns to build a road to each of the four other towns without creating any intersections?"},
   "mzp": {"xml:id": "", "permid": "mzp", "ptxtag": "li", "parent": ["ooC","content"],
           "content": "<&>LbZ<;>"},
   "LbZ": {"xml:id": "", "permid": "LbZ", "ptxtag": "p", "parent": ["mzp","content"],
           "content": "The most popular mathematician in the world is throwing a party for all of his friends.\n As a way to kick things off, they decide that everyone should shake hands.\n Assuming all 10 people at the party each shake hands with every other person\n (but not themselves,\n obviously)\n exactly once, how many handshakes take place?"},
   "SGy": {"xml:id": "", "permid": "SGy", "ptxtag": "li", "parent": ["ooC","content"],
           "content": "<&>rji<;>"},
   "rji": {"xml:id": "", "permid": "rji", "ptxtag": "p", "parent": ["SGy","content"],
           "content": "At the warm-up event for Oscar's All Star Hot Dog Eating Contest, Al ate one hot dog.\n Bob then showed him up by eating three hot dogs.\n Not to be outdone, Carl ate five.\n This continued with each contestant eating two more hot dogs than the previous contestant.\n How many hot dogs did Zeno (the 26th and final contestant) eat?\n How many hot dogs were eaten all together?"},
   "223344": {"xml:id": "", "permid": "", "ptxtag": "m", "parent": ["ACU","content"],
           "content": "[0, \\infty)"},
   "yNH": {"xml:id": "", "permid": "yNH", "ptxtag": "li", "parent": ["ooC","content"],
           "content": "<&>Xqr<;><&>ssiiddee<;><&>DxA<;>"},
   "Xqr": {"xml:id": "", "permid": "Xqr", "ptxtag": "p", "parent": ["yNH","content"],
           "content": "After excavating for weeks, you finally arrive at the burial chamber.\nThe room is empty except for two large chests.\n On each is carved a message (strangely in English):"},
   "ssiiddee": {"xml:id": "", "permid": "", "ptxtag": "bareimage", "parent": ["yNH","content"],
           "content": "<&>ppccii<;>",
           "class": "image-box",   // maybe that is inherent to bareimage ?
           "style": "width: 66%; margin-right: 17%; margin-left: 17%"},
   "ppccii": {"xml:id": "", "permid": "", "ptxtag": "img", "parent": ["ssiiddee","content"],
           "src": "images/two-chests.svg", "alt": "alt text goes here"},
   "DxA": {"xml:id": "", "permid": "", "ptxtag": "p", "parent": ["yNH","content"],
           "content": "You know exactly one of these messages is true.\nWhat should you do?"}
}



function local_menu_navigator(e) {
    e.preventDefault();
    console.log("in the local_menu_navigator");
    if (e.code == "Tab") {
        if (!document.getElementById('local_menu_holder')) {  // no local menu, so make one
            local_menu_for('actively_editing');
        }  else {  //Tab must be cycling through a menu
            // this is copied from main_menu_navigator, so maybe consolidate
            current_active_menu_item = document.getElementById('choose_current');
            next_menu_item = current_active_menu_item.nextSibling;
            console.log("current_active_menu_item", current_active_menu_item, "next_menu_item", next_menu_item);
            if (!next_menu_item) { next_menu_item = current_active_menu_item.parentNode.firstChild }
            console.log("current_active_menu_item", current_active_menu_item, "next_menu_item", next_menu_item);
            current_active_menu_item.removeAttribute("id");
            console.log("current_active_menu_item", current_active_menu_item, "next_menu_item", next_menu_item);
            next_menu_item.setAttribute("id", "choose_current");
            console.log("setting focus on",next_menu_item);
            next_menu_item.focus();
        }
    } else {
        console.log("local_menu_navigator calling main_menu_navigator");
        main_menu_navigator(e)
    }
}

function ptx_to_html(input_text) {
    output_text = input_text;

// there are two types of expansion to be done:
//    expand internal tags
//    convert hand-written ptx to HTML
    output_text = expand_condensed_source_html(output_text, "ptx");

    output_text = output_text.replace(/<term>/g, "<b>"); 
    output_text = output_text.replace(/<\/term>/g, "</b>"); 
    return(output_text)
}

function extract_internal_contents(some_text) {

    // some_text must be a paragraph with mixed content only contining
    // non-nested tags
    the_text = some_text;
 //   console.log("            xxxxxxxxxx  the_text is", the_text);
    console.log("extract_internal_contents");
    if (the_text.includes('data-editable="99" tabindex="-1">')) {
        return the_text.replace(/<([^<]+) data-editable="99" tabindex="-1">(.*?)<[^<]+>/g, save_internal_cont)
    } else if(the_text.includes('$ ')) {   // not general enough
         return the_text.replace(/(^|\s)\$([^\$]+)\$(\s|$|[.,!?;:])/g, extract_new_math)
    } else {
    return the_text
    }
}

function extract_new_math(match, sp_before, math_content, sp_after) {
    new_math_id = randomstring();
    internalSource[new_math_id] = { "xml:id": new_math_id, "permid": "", "ptxtag": "m",
                          "content": math_content}
    return sp_before + "<&>" + new_math_id + "<;>" + sp_after
}

function save_internal_cont(match, contains_id, the_contents) {
    this_id = contains_id.replace(/.*id="(.+?)".*/, '$1');

    console.log("id", this_id, "now has contents", the_contents);
    internalSource[this_id]["content"] = the_contents;
    return "<&>" + this_id + "<;>"
}
function assemble_internal_version_changes() {
    console.log("in assemble_internal_version_changes");
    console.log("current active element to be saved", document.activeElement);
    console.log("which has parent", document.activeElement.parentElement);
    console.log("whose age is", document.activeElement.parentElement.getAttribute("data-age"));

    var oldornew = document.activeElement.parentElement.getAttribute("data-age");
    if (!oldornew) { oldornew = document.activeElement.getAttribute("data-age") }
    console.log("    OLDorNEW", oldornew);

    var possibly_changed_ids_and_entry = [];
    var nature_of_the_change = "";

    var object_being_edited = document.activeElement;
    var location_of_change = object_being_edited.parentElement;

    if (object_being_edited.classList.contains("paragraph_input")) {
        nature_of_the_change = "replace";
        var paragraph_content = object_being_edited.innerHTML;
    //    console.log("paragraph_content from innerHTML", paragraph_content);
        paragraph_content = paragraph_content.trim();

        var cursor_location = object_being_edited.selectionStart;

        console.log("cursor_location", cursor_location, "out of", paragraph_content.length, "paragraph_content", paragraph_content);

        // does the textbox contain more than one paragraph?
        var paragraph_content_list = paragraph_content.split("<div><br></div>");
        console.log("there were", paragraph_content_list.length, "paragraphs, but some may be empty");
        for (var j=0; j < paragraph_content_list.length; ++j) {

            console.log("paragraph", j, "begins", paragraph_content_list[j].substring(0,20))
        }

        var parent_and_location = [object_being_edited.getAttribute("data-parent_id"), object_being_edited.getAttribute("data-parent_component")];
        var this_arrangement_of_objects = "";
        console.log("parent_and_location", parent_and_location);
        console.log("of ", object_being_edited);

        var prev_id = object_being_edited.getAttribute("data-source_id");
        console.log("prev_id", prev_id);
        console.log("which is", prev_id);

        var  paragraph_content_list_trimmed = [];

        for (var j=0; j < paragraph_content_list.length; ++j) {
            // probably each paragraph is wrapped in meaningless div tags
            var this_paragraph_contents_raw = paragraph_content_list[j];
            this_paragraph_contents_raw = this_paragraph_contents_raw.replace(/<\/div><div>/g, "\n");
            this_paragraph_contents_raw = this_paragraph_contents_raw.replace(/<div>/g, "");
            this_paragraph_contents_raw = this_paragraph_contents_raw.replace(/<\/div>/g, "");
            this_paragraph_contents_raw = this_paragraph_contents_raw.replace(/&nbsp;/g, " ");
            this_paragraph_contents_raw = this_paragraph_contents_raw.replace(/ +<br>/g, "\n");
            this_paragraph_contents_raw = this_paragraph_contents_raw.replace(/<br>/g, "\n");
            this_paragraph_contents_raw = this_paragraph_contents_raw.trim();
            if (!this_paragraph_contents_raw) { console.log("empty paragraph") }
            else { paragraph_content_list_trimmed.push(this_paragraph_contents_raw) }
       //     console.log("this_paragraph_contents_raw", this_paragraph_contents_raw);
            console.log("done transforming paragraph", j, "with object_being_edited",object_being_edited);
            console.log("which has contents", this_paragraph_contents_raw.substring(0,20))
        }

        if (!paragraph_content_list_trimmed.length ) { 
                // empty, so insert it and delete it later
            nature_of_the_change = "empty";  // not sure this is used
            paragraph_content_list_trimmed = [""];
        }

        for (var j=0; j < paragraph_content_list_trimmed.length; ++j) {

            console.log("_trimmed paragraph", j, "begins", paragraph_content_list_trimmed[j].substring(0,20))
        }
        for (var j=0; j < paragraph_content_list_trimmed.length; ++j) {
            var this_paragraph_contents = paragraph_content_list_trimmed[j];
            console.log("this_paragraph_contents", this_paragraph_contents.substring(0,20));
            if (j == 0 && prev_id) {
                if (prev_id in internalSource) {
                    // the content is referenced, so we update the referenced content
                       // need to check internal content, such as em or math
                    this_paragraph_contents = extract_internal_contents(this_paragraph_contents);
                    if (internalSource[prev_id]["content"] != this_paragraph_contents) {
                        if (internalSource[prev_id]["content"]) {
                            current_editing_actions.push(["changed", "p", prev_id]);
                        } else if (this_paragraph_contents) {
                            current_editing_actions.push(["new", "p", prev_id]);
                        }
                        internalSource[prev_id]["content"] = this_paragraph_contents;
                        console.log("changed content of", prev_id)
                    } else if (!this_paragraph_contents) {  // adding an empty paragraph
                        current_editing_actions.push(["empty", "p", prev_id]);
                    } else {
                        // this means the contents are nonempty and unchanged, so don't record is as a change
                    }
                    possibly_changed_ids_and_entry.push([prev_id, "content", oldornew]);
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

                // put the new p after the previous p in the string describing the neighboring contents
                var object_before = new RegExp('(<&>' + prev_id + '<;>)');
                this_arrangement_of_objects = this_arrangement_of_objects.replace(object_before, '$1' + '\n<&>' + this_object_label + '<;>');
                prev_id = this_object_label;
                
                this_paragraph_contents = extract_internal_contents(this_paragraph_contents);
                this_object_internal["content"] = this_paragraph_contents;
                internalSource[this_object_label] = this_object_internal
                console.log("just inserted at label", this_object_label, "content starting", this_paragraph_contents.substring(0,11));
                current_editing_actions.push(["added", "p", this_object_label]);
// here is where we can record that somethign is empty, hence should be deleted
                possibly_changed_ids_and_entry.push([this_object_label, "content", "new"]);
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
        console.log("the content (is it a creator?) is", line_content);
        var owner_of_change = object_being_edited.getAttribute("data-source_id");
        var component_being_changed = object_being_edited.getAttribute("data-component");
        console.log("component_being_changed", component_being_changed, "within", owner_of_change);
        // update the title of the object
        if (internalSource[owner_of_change][component_being_changed]) {
            current_editing_actions.push(["changed", "creator", owner_of_change]);
        } else {
            current_editing_actions.push(["added", "creator", owner_of_change]);
        }
        internalSource[owner_of_change][component_being_changed] = line_content;
        possibly_changed_ids_and_entry.push([owner_of_change, "creator"]);

    } else if (object_being_edited.classList.contains("image_source")) {
        // currently this only handles images by URL.
        // later do the case of uploading an image.
        var image_src = object_being_edited.innerHTML;

        // what is the right way to do this?
        image_src = image_src.replace(/<div>/g, "");
        image_src = image_src.replace(/<\/div>/g, "");
        image_src = image_src.trim();
        console.log("changing img src to", image_src);

        var owner_of_change = object_being_edited.getAttribute("data-source_id");
        // the owner_of_change is bareimage, but the src is in the img in its contents
        var image_being_changed = internalSource[owner_of_change]["content"];
        // strip off <&> and <;>
   //     image_being_changed = image_being_changed[3:-3];
        image_being_changed = image_being_changed.replace(/<&>(.*?)<;>/, '$1');
        console.log("image_being_changed ", image_being_changed);
        console.log("object being changed ", internalSource[owner_of_change]);
        console.log("image being changed was", internalSource[image_being_changed]);

        if (internalSource[image_being_changed]["src"]) {
            current_editing_actions.push(["changed", "src", image_being_changed]);
        } else {
            current_editing_actions.push(["added", "src", image_being_changed]);
        }
        internalSource[image_being_changed]["src"] = image_src;
        console.log("image being changed is", internalSource[image_being_changed]);
        possibly_changed_ids_and_entry.push([owner_of_change, "bareimage"]);


    } else {
        alert("don;t know how to assemble internal_version_changes of", object_being_edited.tagName)
    }
    console.log("finished assembling internal version, which is now:",internalSource);
    console.log("    NUMBER of things chagnged:", possibly_changed_ids_and_entry.length);
    return [nature_of_the_change, location_of_change, possibly_changed_ids_and_entry]
}

function expand_condensed_source_html(text, context) {
    console.log("iiiiiii     in expand_condensed_source_html");
    if (text.includes("<&>")) {
        console.log("     qqqqq      expand_condensed_source_html", text);
        if (context == "edit") {
            return text.replace(/<&>(.*?)<;>/g,expand_condensed_src_edit)
         } else {
            return text.replace(/<&>(.*?)<;>/g,expand_condensed_src_html)
         }
    } else {
    console.log("returning text XX" + text.substring(0,17) + "YY");
    console.log("returning from expand_condensed_source_html");
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
    console.log("making html of", the_object, "is_inner", is_inner, "the_id", the_id);
    var ptxtag = the_object["ptxtag"];
    console.log("which has tag", ptxtag);

    var the_html_objects = [];

    if (ptxtag == "p") {
        console.log("need to decide if a p is a p or a div");
        var the_content = the_object["content"];
        var opening_tag="<p ", closing_tag="</p>";

        if(is_inner == "edit") {
            opening_tag= ""; //"<div ";
            closing_tag= ""; // "</div>";

            return opening_tag + expand_condensed_source_html(the_content, is_inner) + closing_tag

        } else if (is_inner == "inner") {
            opening_tag += 'id="' + the_id + '"';
            opening_tag += ' data-editable="99" tabindex="-1"';

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
            opening_tag += ' data-editable="98" tabindex="-1"';
            opening_tag += '>';
            var closing_tag = '</li>';
            return opening_tag + the_content + closing_tag
        }

        html_of_this_object = document.createElement('li');
        html_of_this_object.setAttribute("data-editable", 98);
        html_of_this_object.setAttribute("tabindex", -1);
        html_of_this_object.setAttribute("id", the_id);

        html_of_this_object.innerHTML = the_content
        the_html_objects.push(html_of_this_object);
    } else if (ptxtag == "bareimage") {
        var the_content = the_object["content"];
        console.log("inserting a bare image with content", the_content);
        the_content = expand_condensed_source_html(the_content, is_inner);
        console.log("which now has content", the_content);

//        if ("edit inner".includes(is_inner)) {
//                // should the id be the_id ?
//            var opening_tag = '<div id="' + the_id + '"';
//            opening_tag += ' data-editable="98" tabindex="-1"';
//            opening_tag += ' class="image-box"';
//            opening_tag += '>';
//            var closing_tag = '</div>';
//            return opening_tag + the_content + closing_tag
//        }

        html_of_this_object = document.createElement('div');
        html_of_this_object.setAttribute("data-editable", 98);
        html_of_this_object.setAttribute("tabindex", -1);
        html_of_this_object.setAttribute("id", the_id);
        html_of_this_object.setAttribute("class", "image-box");
        html_of_this_object.setAttribute("style", "width: 66%; margin-right: 17%; margin-left: 17%");

        html_of_this_object.innerHTML = the_content
        the_html_objects.push(html_of_this_object);
    } else if (ptxtag == "img") {
        var the_src = the_object["src"];
        console.log("inserting an img with src", the_src);

        if ("edit".includes(is_inner)) {
                // should the id be the_id ?
            return the_src
        }

        html_of_this_object = document.createElement('img');
        html_of_this_object.setAttribute("id", the_id);
        html_of_this_object.setAttribute("src", the_src);

        html_of_this_object = '<img src="' + the_src + '" id="' + the_id + '">';

  //      html_of_this_object.innerHTML = the_content
        the_html_objects.push(html_of_this_object);
    } else if (ptxtag in inline_tags) {   // assume is_inner?
        var opening_tag = inline_tags[ptxtag][1][0];
        opening_tag += ' id="' + the_id + '"data-editable="50" tabindex="-1">';
        var closing_tag = inline_tags[ptxtag][1][1];
        return opening_tag + the_object["content"] + closing_tag
    } else if (ptxtag in math_tags) {
        // here we are assuming the tag is 'm'
        var opening_tag = '<span class="edit_inline_math"';
        var closing_tag = '</span>';
        if (is_inner == "edit") {
            opening_tag += ' id="' + the_id + '"data-editable="42" tabindex="-1">';
        } else {
            opening_tag = math_tags[ptxtag][1][0];
            closing_tag = math_tags[ptxtag][1][1];
        }
        return opening_tag + spacemath_to_tex(the_object["content"]) + closing_tag
    } else if (ptxtag == "proof") {  // maybe consolidate with remark-like
        object_in_html = document.createElement("article");
        object_in_html.setAttribute("id", the_id);
        object_in_html.setAttribute("class", ptxtag);
        object_in_html.setAttribute("tabindex", -1);
        object_in_html.setAttribute("data-editable", 60);
        var headertag = "h6";
        object_heading_html = '<' + headertag;
        object_heading_html += ' class="heading" data-parent_id="' + the_id + '">';
        object_heading_html += '<span class="type">Proof</span>';
        object_heading_html += '<span class="period">' + "." + '</span>';
        object_heading_html += '</' + headertag + '>';

        var object_statement_ptx = the_object["content"];
        object_statement_html =  expand_condensed_source_html(object_statement_ptx);
        console.log("proof statement is", object_statement_html);
        object_in_html.innerHTML = object_heading_html + object_statement_html;
        the_html_objects.push(object_in_html);

    } else if (editing_container_for["definition-like"].includes(ptxtag) ||
               editing_container_for["theorem-like"].includes(ptxtag) ||
               editing_container_for["remark-like"].includes(ptxtag) ||
               editing_container_for["example-like"].includes(ptxtag) ||
               editing_container_for["exercise-like"].includes(ptxtag) ||
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
        if (editing_container_for["section-like"].includes(ptxtag)) {
            object_in_html.setAttribute("data-editable", 66);
        } else {
            object_in_html.setAttribute("data-editable", 95);
        }

        object_title = the_object["title"];
        object_creator = the_object["creator"];

        object_in_html.setAttribute("id", the_id);

        object_heading_html = '<' + headertag;
        object_heading_html += ' class="heading" data-parent_id="' + the_id + '">';
        var objecttype_capped = ptxtag.charAt(0).toUpperCase() + ptxtag.slice(1);
        object_heading_html += '<span class="type" data-editable="70" tabindex="-1">' + objecttype_capped + '</span>';
        object_heading_html += '<span class="space">' + " " + '</span>';
        object_heading_html += '<span class="codenumber">' + "#N" + '</span>';

        if (object_title) {
            object_heading_html += '<span class="title" data-editable="75" tabindex="-1">' + object_title + '</span>';
        }
        if (object_creator) {
            object_heading_html += '<span class="space">' + " " + '</span>';
            object_heading_html += '<span class="creator" data-editable="73" tabindex="-1">(' + object_creator + ')</span>';
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
        console.log("statement statement is", object_statement_html);

        object_in_html.innerHTML = object_heading_html + object_statement_html;

        the_html_objects.push(object_in_html);

    } else {
         alert("don't know how to make html from", the_object)
    }
    console.log("    RRRR returning the_html_objects", the_html_objects);
    return the_html_objects
}

function insert_html_version(these_changes) {

    var nature_of_the_change = these_changes[0];
    var location_of_change = these_changes[1];
    var possibly_changed_ids_and_entry = these_changes[2];

    console.log("nature_of_the_change", nature_of_the_change);
    console.log("location_of_change", location_of_change);
    console.log("possibly_changed_ids_and_entry", possibly_changed_ids_and_entry);

    if (!possibly_changed_ids_and_entry.length) {
        console.log("nothing to change");
  //      return ""
    }
    // we make HTML version of the objects with ids possibly_changed_ids_and_entry,
    // and then insert those into the page.  

// here is where we detect deleting?
// or is that after this function is done?
    if (nature_of_the_change != "replace") {
        console.log("should be replace, since it is the edit form we are replacing");
 //       alert("should be replace, since it is the edit form we are replacing")
    }

    var object_as_html = "";
    var this_object_id, this_object_entry, this_object_oldornew, this_object;

    console.log(" there are", possibly_changed_ids_and_entry.length, "items to process");

    for (var j=0; j < possibly_changed_ids_and_entry.length; ++j) {
        this_object_id = possibly_changed_ids_and_entry[j][0];
        this_object_entry = possibly_changed_ids_and_entry[j][1];
        this_object_oldornew = possibly_changed_ids_and_entry[j][2];
        this_object = internalSource[this_object_id];
        console.log(j, "this_object", this_object);
        if (this_object["ptxtag"] == "p" || this_object["ptxtag"] == "li") {
          //  object_as_html = document.createElement('p');
            object_as_html = document.createElement(this_object["ptxtag"]);
            if (this_object["ptxtag"] == "p") {
                object_as_html.setAttribute("data-editable", 99);
            } else {
                object_as_html.setAttribute("data-editable", 98);
            }
            object_as_html.setAttribute("tabindex", -1);
            object_as_html.setAttribute("id", this_object_id);
            object_as_html.setAttribute("data-age", this_object_oldornew);
            console.log("now making inner HTML", this_object[this_object_entry].substring(0,12));
            object_as_html.innerHTML = ptx_to_html(this_object[this_object_entry]);
            location_of_change.insertAdjacentElement('beforebegin', object_as_html);
            var editing_parent = current_editing["tree"][ current_editing["level"] -1 ][ current_editing["location"][ current_editing["level"] - 1 ] ];
            console.log("               editing_parent", editing_parent);
            console.log("       EEE   ", current_editing["level"], "     current_editing[tree]", current_editing["tree"], " EEE ", current_editing["tree"][current_editing["level"]]);
            current_editing["tree"][current_editing["level"]] = next_editable_of(editing_parent, "children");
        } else if (this_object_entry == "creator") {
            var object_as_html = document.createElement('span');
            object_as_html.setAttribute("class", "creator");
            object_as_html.innerHTML = ptx_to_html(this_object[this_object_entry]);
            console.log("inserting",object_as_html,"before",location_of_change);
            location_of_change.insertAdjacentElement('beforebegin', object_as_html);

        } else if (this_object_entry == "bareimage") {
            var object_as_html = document.createElement('div');
            object_as_html.setAttribute("data-editable", 98);
            object_as_html.setAttribute("tabindex", -1);
            object_as_html.setAttribute("id", this_object_id);
            object_as_html.setAttribute("class", "image-box");
            object_as_html.setAttribute("style", "width: 50%; margin-right: 25%; margin-left: 25%");

            console.log("this_object", this_object);
            object_as_html.innerHTML = ptx_to_html(this_object["content"]);
            console.log("inserting",object_as_html,"before",location_of_change);
            location_of_change.insertAdjacentElement('beforebegin', object_as_html);

        } else {
            console.log("trouble making", this_object);
         //   alert("I don; tknow how to make a", this_object["ptxtag"]);
        }
        MathJax.Hub.Queue(['Typeset', MathJax.Hub, this_object_id]);
    }
    location_of_change.remove();

    console.log("returning from", insert_html_version);
    // call mathjax, in case the new content contains math
    return object_as_html // the most recently added object, which we may want to
                           // do something, like add an editing menu
}

function save_edits() {

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
    var most_recent_edit;
    if (e.code == "Tab") {
        e.preventDefault();
        console.log("making a local menu");
        local_menu_navigator(e);
    } else if (e.code == "Escape" || e.code == "Enter") {
        console.log("I saw a Rettttt");
        if (document.activeElement.tagName == "INPUT") {
            console.log("probably saving a creator");
            e.preventDefault();
            these_changes = assemble_internal_version_changes();
            final_added_object = insert_html_version(these_changes);
            most_recent_edit = current_editing_actions.pop();
            recent_editing_actions.unshift(most_recent_edit);
            console.log("most_recent_edit should be title change", most_recent_edit);
            console.log("final_added_object", final_added_object);
            document.getElementById("actively_editing_statement").focus();
      //      document.getElementById("actively_editing_statement").setSelectionRange(0,0);
            this_char = "";
            prev_char = "";
            save_edits()
// editing_input_image
        } else if (e.code == "Escape" || (prev_char.code == "Enter" && prev_prev_char.code == "Enter") || document.getElementById("editing_input_image")) {
            console.log("need to save");
console.log("    HHH current_editing", current_editing);

            e.preventDefault();
            this_char = "";
            prev_char = "";
            these_changes = assemble_internal_version_changes();
            console.log("    CCC these_changes", these_changes);
            console.log("    CCC0 these_changes[0]", these_changes[0]);
            console.log("current_editing_actions", current_editing_actions);
            console.log("actively_editing", document.getElementById("actively_editing"));
console.log("    III current_editing", current_editing, current_editing["tree"][current_editing["level"]]);
            previous_added_object = final_added_object;
            final_added_object = insert_html_version(these_changes);
            console.log("final_added_object, previous_added_object", final_added_object, previous_added_object);
console.log("    LLL current_editing", current_editing, current_editing["tree"][current_editing["level"]]);
            console.log("the final_added_object", final_added_object);
            console.log("the actively_editing", document.getElementById("actively_editing"));
            console.log("OO", current_editing_actions.length, " current_editing_actions", current_editing_actions);
            console.log("current_editing_actions[0]", current_editing_actions[0]);
            console.log("current_editing_actions[0][2]", current_editing_actions[0][2]);
                // maybe this next if only handles when we delete by removing the letters in a p?
            if (these_changes[0] == "empty") {
                console.log("NN", current_editing_actions.length, " current_editing_actions", current_editing_actions);
                console.log("current_editing_actions[0]", current_editing_actions[0]);
                console.log("current_editing_actions[0][2]", current_editing_actions[0][2]);
                console.log("            going to delete", these_changes[2][0]);
                // this is sort-of a hack to detext the end of inserting li
                if (current_editing_actions.length == 2 &&
                    current_editing_actions[1][0] == "empty" &&
                    current_editing_actions[1][1] == "p" &&
                    current_editing_actions[0][0] == "new" &&
                    current_editing_actions[0][1] == "li") {
                    current_editing_actions.pop();   // content was empty, so there is no editing action
                    current_editing_actions.pop();
                    delete_by_id(these_changes[2][0][0], "newempty");
                    current_editing["location"][current_editing["level"]] -= 1
                    final_added_object = previous_added_object;  // this approach makes the updating of current_editing moot?
                } else {
                    delete_by_id(these_changes[2][0][0], "empty");
                }
                console.log("MM", current_editing_actions.length, " current_editing_actions", current_editing_actions);
                for (var j=0; j<current_editing_actions.length; ++j ) {
                    console.log(j, "current_editing_actions[j]", current_editing_actions[j]);
                }
                console.log("PP", current_editing_actions.length, " current_editing_actions", current_editing_actions);
            }
            // if there is an editing paragraph ahead, go there.  Otherwise menu the last thing added
            if (document.querySelector('.paragraph_input')) {
                next_textarea = document.querySelector('.paragraph_input');
                console.log("focus to next_textarea", next_textarea);
                next_textarea.focus();
       //         next_textarea.setSelectionRange(0,0);
            } else if (final_added_object) { //  && document.getElementById("actively_editing")) {

              if(document.getElementById("actively_editing")) {
console.log("    SSS current_editing", current_editing, current_editing["tree"][current_editing["level"]]);

                var editing_placeholder = document.getElementById("actively_editing");
                console.log("still editing", editing_placeholder, "which contains", final_added_object);
                var this_parent = internalSource[final_added_object.id]["parent"];
                console.log("final_added_object parent", this_parent);
                var the_whole_object = html_from_internal_id(this_parent[0]);
                console.log("the_whole_object", the_whole_object);
                if (internalSource[this_parent[0]]["ptxtag"] == "proof") { // insert the theorem-like statement
                    var the_parent_object = html_from_internal_id(internalSource[this_parent[0]]["parent"][0]);
                    the_whole_object = the_parent_object.concat(the_whole_object)
                }
                for (var j = the_whole_object.length - 1; j >= 0; --j) {
                    console.log("   X", j, "the_whole_object[j]", the_whole_object[j]);
                    document.getElementById("actively_editing").insertAdjacentElement("afterend", the_whole_object[j])
                    MathJax.Hub.Queue(['Typeset', MathJax.Hub, the_whole_object[j]]);

                }
                
                console.log("here is where we need to update current_editing", "parent:", this_parent,"which is",document.getElementById(this_parent[0]), "level:", current_editing["level"], "loation:", current_editing["location"], "tree:", current_editing["tree"]);
                $("#actively_editing").remove();

console.log("    DDD current_editing", current_editing, current_editing["tree"][current_editing["level"]]);

              }

                most_recent_edit = ["","",""];
                while (current_editing_actions.length) {
                    most_recent_edit = current_editing_actions.pop();
                    recent_editing_actions.unshift(most_recent_edit);
                    console.log("      most_recent_edit", most_recent_edit);
                }
                console.log("      final_added_object", final_added_object);

                save_edits()

                // is this in the right place?
                console.log("most_recent_edit", most_recent_edit);

                // sometimes, such as when adding items to a list, you want to
                // automatically start adding something else.
                // maybe refactor theorem to add proof after?
                if (most_recent_edit[1] == "li") {  // added to a list, so try adding again
                      //  note that when adding an li, the neichbor is a p within the actual li neighbor
                    var new_obj = create_object_to_edit("li", document.getElementById(most_recent_edit[2]).firstElementChild, "afterend")
                    edit_in_place(new_obj, "new");
                    console.log("now editing the assumed new li");
console.log("    GGG current_editing", current_editing, current_editing["tree"][current_editing["level"]]);
           //         alert("now editing the new li");
                } else {

                var editing_parent = current_editing["tree"][ current_editing["level"] -1 ][ current_editing["location"][ current_editing["level"] - 1 ] ];
                console.log("going to make the new tree from parent of", this_parent, "which is", editing_parent, "and has children", next_editable_of(editing_parent, "children"));
                current_editing["tree"][current_editing["level"]] = next_editable_of(editing_parent, "children");    
                console.log("updated tree", current_editing["tree"]);
console.log("    QQQ current_editing", current_editing, current_editing["tree"][current_editing["level"]]);
console.log("    final_added_object", final_added_object);

                make_current_editing_from_id(final_added_object.id);


                edit_menu_from_current_editing("entering");

                }

            } else if ( document.getElementById("actively_editing")) {
                 document.getElementById("actively_editing").remove();
                edit_menu_from_current_editing("entering");
            } else {
                edit_menu_from_current_editing("entering");
            }   
        }  //  esc or enter enter enter
        console.log ("processed an enter");
    } //  esc or enter
      else {
        console.log("e.code was not one of those we were looking for", e)
    }
    console.log("leaving local_editing_action")
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

    if (document.getElementById("enter_choice")) {
        theEnterChoice = document.getElementById("enter_choice");
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
            if (current_level == 0) { // at the top, so no "next" object
                return ""
            }
            // go to next sibling, or stage to exit if on last sibling
            if (current_location == (current_siblings.length - 1)) { // on last sibling
                    console.log("on last sibling, level was", current_level,"siblings was", current_siblings, "tree", current_editing["tree"]);
                    console.log("current_location was", current_location);
                    current_level -= 1;
                    current_location = current_editing["location"][current_level];
                    current_editing["level"] = current_level;
                    current_editing["location"][current_level] = current_location;
                    current_siblings = current_editing["tree"][current_level];
                    console.log("current_location is", current_location);
                    console.log("stay menu A");
                    object_of_interest.classList.remove("may_leave");
                    object_of_interest.classList.remove("may_elect");
                    edit_menu_from_current_editing("leaving")
            } else {
                console.log("moving to the next editable sibling");
                    console.log("level was", current_level,"siblings was", current_siblings, "tree", current_editing["tree"]);
                    console.log("current_location was", current_location);
                console.log(current_location, "was", current_editing);
                current_location += 1;
                object_of_interest.classList.remove("may_leave");
                object_of_interest.classList.remove("may_elect");
                    console.log("current_location is", current_location);
              console.log("stay menu B");
                current_editing["location"][current_level] = current_location;
                console.log(current_location, "is", current_editing);
                edit_menu_from_current_editing("entering")
            }
        } else if ((e.code == "Tab" && e.shiftKey) || e.code == "ArrowUp") {  // Shift-Tab to prevous object
            e.preventDefault();
            // go to previous sibling, or up one if on first sibling
            console.log("Arrow Up:", "current_location", current_location, "current_level", current_level);
            if (theMotion == "stay") {  // about to leave, to return to the top of that region
                edit_menu_from_current_editing("entering")
            } else if (current_location == 0) {
                if (!current_level) { // already at the top, so nowhere to go, so do nothing
                    console.log("at the top, so can't go up");
                    return ""
                }
                current_level -= 1;
                current_editing["level"] = current_level;
                current_location = current_editing["location"][current_level];
                console.log("AA new current_location", current_location, " current_editing['tree']",  current_editing["tree"]);
                console.log(" current_editing['tree'][0]",  current_editing["tree"][0]);
                current_siblings = current_editing["tree"][current_level];
                console.log("current_siblings", current_siblings);
                edit_menu_from_current_editing("entering")
            } else {
                current_location -= 1;
                current_editing["location"][current_level] = current_location;
                console.log("current_siblings", current_siblings);
                console.log("BB new current_location", current_location, "at level", current_level, " current_editing['tree']",  current_editing["tree"]);
                edit_menu_from_current_editing("entering")
            }
        } else if (e.code == "Escape" || e.code == "ArrowLeft") {
            e.preventDefault();
            if (current_level == 0) { return "" } // already at the top, so nowhere to go, so do nothing
// copied from A1
            console.log("At ArrowLeft, level was", current_level, "with location",  current_editing["location"], "and tree", current_editing["tree"][current_level]);
            current_level -= 1;
            current_editing["level"] = current_level;
            current_location = current_editing["location"][current_level];
            current_siblings = current_editing["tree"][current_level];
            console.log("now level id", current_level, "with location",  current_editing["location"], "and tree", current_editing["tree"][current_level]);
            edit_menu_from_current_editing("entering")
        } else if (e.code == "Enter" || e.code == "ArrowRight") {
            e.preventDefault();
            if (theMotion == "stay") {
                edit_menu_from_current_editing("entering");
                return ""
            } 
            var edit_submenu = document.createElement('ol');
            edit_submenu.setAttribute('id', 'edit_menu');

            var to_be_edited = object_of_interest;
            console.log("to_be_edited", to_be_edited);
            console.log("option", top_menu_options_for(to_be_edited));
            edit_submenu.innerHTML = top_menu_options_for(to_be_edited);
            $("#enter_choice").replaceWith(edit_submenu);
            document.getElementById('choose_current').focus();
        }
        console.log("   Just handled the case of enter_choice");
        return ""

    } else if (document.getElementById("choose_current")) {
        var theChooseCurrent = document.getElementById("choose_current");
        var dataLocation = theChooseCurrent.getAttribute("data-location");  // may be null
        var dataAction = theChooseCurrent.getAttribute("data-action");  // may be null
        var dataModifier = theChooseCurrent.getAttribute("data-modifier");  // may be null
        var dataEnv = theChooseCurrent.getAttribute("data-env");  // may be null
        var dataEnvParent = theChooseCurrent.getAttribute("data-env-parent");  // may be null
        var object_of_interest;
        if (document.getElementById("edit_menu_holder")) {
            object_of_interest = document.getElementById("edit_menu_holder").parentElement
        } else {
            object_of_interest = document.getElementById("local_menu_holder").parentElement
        }
        current_level = current_editing["level"];
        current_location = current_editing["location"][current_level];
        current_siblings = current_editing["tree"][current_level];
        console.log("in choose_current", dataLocation, "of", object_of_interest);
        console.log("dataAction ", dataAction);
          // we have an active menu, and have selected an item
          // there are three main sub-cases, depending on whether there is a data-location attribute,
          // a data-action attribute, or a data-env attribute

          // however, some actions (such as Tab and shift-Tab) are the same
          // in each sub-case (because all we are doing is moving up and down the
          // current list of options), so we handle those first.

        if ((e.code == "Tab" || e.code == "ArrowDown") && !e.shiftKey) {
            e.preventDefault();
            next_menu_item = theChooseCurrent.nextSibling;
            console.log("theChooseCurrent", theChooseCurrent, "next_menu_item", next_menu_item);
            if (!next_menu_item) { next_menu_item = theChooseCurrent.parentNode.firstChild }
            console.log("theChooseCurrent", theChooseCurrent, "next_menu_item", next_menu_item);
            if (theChooseCurrent == next_menu_item) { //only one item on menu, so Tab shold move to the next editable item
                current_location += 1;
                console.log("single item menu, current_location now", current_location);
                current_editing["location"][current_level] = current_location;
                edit_menu_from_current_editing("entering");
            }
            theChooseCurrent.removeAttribute("id");
            console.log("theChooseCurrent", theChooseCurrent, "next_menu_item", next_menu_item);
            next_menu_item.setAttribute("id", "choose_current");
            console.log("setting focus on",next_menu_item);
            next_menu_item.focus();
        }  // Tab
          else if ((e.code == "Tab" && e.shiftKey) || e.code == "ArrowUp") {  // Shift-Tab to prevous object
            e.preventDefault();
            console.log("just saw a", e.code);
            console.log("focus is on", $(":focus"));
            console.log("saw an",e.code);
            next_menu_item = theChooseCurrent.previousSibling;
            console.log("W1 theChooseCurrent", theChooseCurrent, "next_menu_item", next_menu_item);
            if (!next_menu_item) { next_menu_item = theChooseCurrent.parentNode.lastChild }
            console.log("W2 theChooseCurrent", theChooseCurrent, "next_menu_item", next_menu_item);
            if (theChooseCurrent == next_menu_item) { //only one item on menu, so Shift-Tab shold move to previous or up one level
                if (current_editing["location"][ current_editing["level"] ] == 0) {
                    current_editing["level"] -= 1;
                } else {
                    current_editing["location"][ current_editing["level"] ] -= 1;
                }
                console.log("single item menu, current_level now", current_level);
                edit_menu_from_current_editing("entering");
            } else {
                theChooseCurrent.removeAttribute("id");
                console.log("W3 theChooseCurrent", theChooseCurrent, "next_menu_item", next_menu_item);
                theChooseCurrent.classList.remove("chosen");
                next_menu_item.setAttribute("id", "choose_current");
                console.log("setting focus on",next_menu_item);
                next_menu_item.focus();
            }
        }
          else if (e.code == "Escape" || e.code == "ArrowLeft") {
            console.log("processing ESC");
            console.log("At ArrowLeft, level was", current_level, "xx", current_editing["level"], "with location",  current_editing["location"], "and tree", current_editing["tree"][current_level]);
   // I think the next if can never be true, because of how to route keystrokes
            if (document.getElementById("local_menu_holder")) {  // hack for when the interface gets confused
                document.getElementById("local_menu_holder").remove()
            } else {
                console.log("W4 theChooseCurrent", theChooseCurrent);
                // need to go up one level in the menu
                var previous_menu_item = theChooseCurrent.parentElement.parentElement;  // li > ol > li
                if (previous_menu_item.id == "edit_menu_holder") {
                    var thenewchoice = '<span id="enter_choice" data-location="next">';
                    thenewchoice += 'edit or add nearby';
                    thenewchoice += '</span>';
                    previous_menu_item.innerHTML = thenewchoice
                } else {
                    theChooseCurrent.parentElement.remove();
                    previous_menu_item.classList.remove('chosen');
                    previous_menu_item.parentElement.classList.remove('past');
                    previous_menu_item.setAttribute("id", "choose_current");
                    previous_menu_item.focus();
                }
            }
      }
        else if (keyletters.includes(e.code)) {
        key_hit = e.code.toLowerCase().substring(3);  // remove forst 3 characters, i.e., "key"
        console.log("key_hit", key_hit);
        theChooseCurrent = document.getElementById('choose_current');
        console.log('theChooseCurrent',  theChooseCurrent );
        console.log( $(theChooseCurrent) );
          // there can be multiple data-jump, so use ~= to find if the one we are looking for is there
          // and start from the beginning in case the match is earlier  (make the second selector better)
        if ((next_menu_item = $(theChooseCurrent).nextAll('[data-jump~="' + key_hit + '"]:first')[0]) ||
            (next_menu_item = $(theChooseCurrent).prevAll('[data-jump~="' + key_hit + '"]:last')[0])) {  // check there is a menu item with that key
            theChooseCurrent.removeAttribute("id", "choose_current");
            next_menu_item.setAttribute("id", "choose_current");
            next_menu_item.focus();
        } else {
            // not sure what to do if an irrelevant key was hit
            console.log("that key does not match any option")
        }
    }

//  Now only Enter and ArrowRight are meaningful in this context.
//  The effect will depend on the other attributes of #choose_current:
//  dataLocation, dataAction, dataEnv

      else if (e.code == "Enter" || e.code == "ArrowRight") {
        e.preventDefault();
        if (dataLocation) {
            if (dataLocation == "enter") {  // we are moving down into an object

                console.log("theChooseCurrent", theChooseCurrent);
                var object_to_be_entered = object_of_interest;
                console.log("object_to_be_entered", object_to_be_entered);
                object_to_be_entered.classList.remove("may_select");
                object_to_be_entered.classList.remove("may_enter");
                object_to_be_entered.classList.remove("may_leave");
                console.log('next_editable_of(object_to_be_entered, "children")', next_editable_of(object_to_be_entered));
                editableChildren = next_editable_of(object_to_be_entered, "children");
                current_level += 1;
                current_editing["level"] = current_level;
                current_editing["location"][current_level] = 0;
                current_editing["tree"][current_level] = editableChildren;
                console.log("current_editing", current_editing);

                console.log("object_to_be_entered", object_to_be_entered);
                console.log("with some children", editableChildren);
               // put  menu on the item at the top of the block_we_are_reentering
                   // this is a repeat of a Tab case, so consolidate
            console.log("menu place 10");
            console.log("document.activeElement", document.activeElement);

                 console.log("menu on", editableChildren[0]);
                 edit_menu_for(editableChildren[0], "entering");

                return ""
            } else if ((dataLocation == "beforebegin") || (dataLocation == "afterend")) {  // should be the only other options
                theChooseCurrent.parentElement.classList.add("past");
                theChooseCurrent.removeAttribute("id");
                theChooseCurrent.classList.add("chosen");

                var parent_id = document.getElementById('edit_menu_holder').parentElement.parentElement.id;
                console.log("making a menu for", parent_id);
                var edit_submenu = document.createElement('ol');
                edit_submenu.innerHTML = menu_options_for(parent_id, "", "base");
                console.log("just inserted inner menu_options_for(" + parent_id + ")", menu_options_for(parent_id, "", "base"));
                theChooseCurrent.insertAdjacentElement("beforeend", edit_submenu);
                document.getElementById('choose_current').focus();
                console.log("focus is on", $(":focus"));

                return ""
            } else {
                console.log("Error: unknown dataLocation:", dataLocation)
            }
        }  // dataLocation

          else if (dataAction) {
            if (dataAction == "edit") {
                console.log("going to edit", object_of_interest);
                edit_in_place(object_of_interest, "old");
            } else if (dataAction == "change-env-to") {
                 // shoudl use dataEnv ?
                var new_env = theChooseCurrent.getAttribute("data-env");
                console.log("changing environment to", new_env);
                       // #edit_menu_holder is in span.type, inside .heading, inside article
                to_be_edited = document.getElementById('edit_menu_holder').parentElement.parentElement.parentElement;
                console.log("to_be_edited", to_be_edited);
                var id_of_object = to_be_edited.id;
                var this_object_source = internalSource[id_of_object];
                console.log("current envoronemnt", this_object_source);
                var old_env = internalSource[id_of_object]["ptxtag"];
                internalSource[id_of_object]["ptxtag"] = new_env;
                recent_editing_actions.push([old_env, new_env, id_of_object]);
                console.log("the change was", "changed " + old_env + " to " + new_env + " " + id_of_object);
                var the_whole_object = html_from_internal_id(id_of_object);
                console.log("B: the_whole_object", the_whole_object);
                $("#" + id_of_object).replaceWith(the_whole_object[0]);  // later handle multiple additions
                console.log("just edited", $("#" + id_of_object));
                // since we changed an object which is in 
                console.log("curent_editing level", current_editing["level"], "with things", current_editing["tree"][current_editing["level"]]);
                current_editing["level"] -= 1;
                current_editing["tree"][current_editing["level"]] = next_editable_of(document.getElementById(id_of_object).parentElement, "children");
                console.log("now curent_editing level", current_editing["level"], "with things", current_editing["tree"][current_editing["level"]]);
                edit_menu_from_current_editing("entering");
                return ""

            } else if (dataAction == 'change-env') {
                       // #edit_menu_holder is in span.type, inside .heading, inside article
                current_env = document.getElementById('edit_menu_holder').parentElement.parentElement.parentElement;
                current_env_id = current_env.id;

                theChooseCurrent.parentElement.classList.add("past");
                theChooseCurrent.removeAttribute("id");
                theChooseCurrent.classList.add("chosen");

                var edit_submenu = document.createElement('ol');
                console.log("J1 lookinh for menu options for", current_env_id);
                edit_submenu.innerHTML = menu_options_for(current_env_id, "", "change");
                console.log("just inserted inner menu_options_for(parent_type)", menu_options_for(current_env_id, "", "change"));
                theChooseCurrent.insertAdjacentElement("beforeend", edit_submenu);
                document.getElementById('choose_current').focus();
                console.log("focus is on", $(":focus"));
            } else if (dataAction == 'modify') {
                       // #edit_menu_holder is in span.type, inside .heading, inside article
                    current_env = document.getElementById('edit_menu_holder').parentElement;
                    current_env_id = current_env.id;

                    if (!dataModifier) {
                        theChooseCurrent.parentElement.classList.add("past");
                        theChooseCurrent.removeAttribute("id");
                        theChooseCurrent.classList.add("chosen");

                        var edit_submenu = document.createElement('ol');
                        console.log("J2a lookinh for menu options for", current_env_id);
                        edit_submenu.innerHTML = menu_options_for(current_env_id, "", "modify");
                        console.log("just inserted inner menu_options_for(parent_type)", menu_options_for(current_env_id, "", "modify"));
                        theChooseCurrent.insertAdjacentElement("beforeend", edit_submenu);
                        document.getElementById('choose_current').focus();
                        console.log("focus is on", $(":focus"));
                    } else if (dataModifier == "done") {
                        edit_menu_from_current_editing("entering");
                    } else if (dataModifier == "arrows") {
                        // setup_arrow_modify()   // is different for images and SBSs
                    } else {
                        modify_by_id_sbs(current_env_id, dataModifier)
                    }
            } else if (dataAction == "move-or-delete") {
                // almost all repeats from dataAction == 'change-env' 
                //  except for current_env and menu_options_for.  Consolidate
                //  maybe also separate actions which give anotehr menu, from actions which change content
                current_env = document.getElementById('edit_menu_holder').parentElement;
                console.log("current_env", current_env);
                current_env_id = current_env.id;

                theChooseCurrent.parentElement.classList.add("past");
                theChooseCurrent.removeAttribute("id");
                theChooseCurrent.classList.add("chosen");

                var edit_submenu = document.createElement('ol');
                console.log("J3 looking for menu options for", current_env_id);
                edit_submenu.innerHTML = menu_options_for(current_env_id, "", "move-or-delete");
                console.log("just inserted inner menu_options_for(parent_type)", menu_options_for(current_env_id, "", "move-or-delete"));
                theChooseCurrent.insertAdjacentElement("beforeend", edit_submenu);
                document.getElementById('choose_current').focus();
                console.log("focus is on", $(":focus"));
            } else if (dataAction == "delete") {
                current_env = document.getElementById('edit_menu_holder').parentElement;
                console.log("current_env", current_env);
                current_env_id = current_env.id;
                delete_by_id(current_env_id, "choice")
            } else if (["move-local", "move-local-p", "move-local-li"].includes(dataAction)) {
                current_env = document.getElementById('edit_menu_holder').parentElement;
                current_env_id = current_env.id;
                handle_env_id = current_env_id;   // we were focused on that p, even though
                                                      // we are moving an li.  Later refocus on p
                if (dataAction == "move-local-li") {
                    current_env.classList.remove("may_select");
                    current_env = current_env.parentElement;
                    current_env.classList.add("may_select");
                    current_env_id = current_env.id;
                }
                console.log("current_env", current_env);
                move_by_id_local(current_env_id, handle_env_id)
            } else if (dataAction == "change-title") {
                console.log("change-title not implemented yet")
            } else {
                alert("I don;t know what to do llllllll dataAction " + dataAction)
            }
        }  // dataAction
          else if (dataEnv) {  // this has to come after dataAction, because if both occur,
                               // dataAction says to do something, and dataEnv says what to do
              e.preventDefault();  // was this handled earlier?
              console.log("in dataEnv", dataEnv);
              console.log("selected a menu item with no action and no location");
              $("#choose_current").parent().addClass("past");
              console.log("apparently selected", theChooseCurrent);
              theChooseCurrent.removeAttribute("id");
              theChooseCurrent.setAttribute('class', 'chosen');

              if (dataEnv in inner_menu_for()) {  // object names a collection, so make submenu
                  console.log("making a menu for", dataEnv);
                  var edit_submenu = document.createElement('ol');
                  edit_submenu.innerHTML = menu_options_for("", dataEnv, "inner");
                  theChooseCurrent.insertAdjacentElement("beforeend", edit_submenu);
                  document.getElementById('choose_current').focus();

                           // determine whether both of these next cases can occur
              } else if ( (dataEnv in editing_container_for) || (dataEnvParent in editing_container_for) ) {
              // we just selected an action, so do it
                      // that probably involves adding something before or after a given object
                  console.log("making a new", dataEnv, "within", dataEnvParent);
                  var before_after = $("#edit_menu_holder > #edit_menu > .chosen").attr("data-location");
                  console.log("create_object_to_edit",dataEnv, object_of_interest, before_after);
                  var new_obj = create_object_to_edit(dataEnv, object_of_interest, before_after);
                  console.log("new_obj", new_obj);
                  edit_in_place(new_obj, "new");
                  var new_obj_id = new_obj.id;
                  console.log("are we editing id", new_obj_id);
                  console.log("are we editing", new_obj);
                  console.log("  JJJ  current_editing", current_editing["level"], current_editing["location"].length, current_editing["tree"].length, current_editing["tree"][current_editing["level"]]);
                  console.log("    current_editing", current_editing);
                  object_of_interest.classList.remove("may_select");
                  object_of_interest.classList.remove("may_enter");
                  document.getElementById('edit_menu_holder').remove();
                  if (dataEnv.startsWith("sbs")) {
                      console.log("added sbs, now add to it");
                      var first_panel_id = document.getElementById(new_obj_id).firstChild.firstChild.id;
                      make_current_editing_from_id(first_panel_id);
                      edit_menu_from_current_editing("entering");
                  }
// sbssbs
              } else {
                  console.log("Error: unknown dataEnv", dataEnv);
                  console.log("moving up the menu -- not");
                  alert("Sorry, not implemented yet!");
                  theChooseCurrent.classList.remove("chosen");
                  theChooseCurrent.parentElement.classList.remove("past");
                  theChooseCurrent.setAttribute("id", "choose_current");
              }
          }
    } //  // dataEnv
      else {
        console.log("key that is not meaningful when navigating a menu:", e.code)
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

    } else if (document.getElementById('phantomobject')) {
        var the_phantomobject = document.getElementById('phantomobject');

        if (the_phantomobject.classList.contains('move')) {
            move_object(e)
        } else {
            alert("do not know what to do with that")
        }
    } else {
        main_menu_navigator(e);
    }
}

// xx 

document.addEventListener('focus', function() {
//  console.log('focused:', document.activeElement)
//  console.log('which has content XX' + document.activeElement.innerHTML + "VV")
  prev_prev_focused_element = prev_focused_element;
  prev_focused_element = this_focused_element;
  this_focused_element = document.activeElement;
  $('.in_edit_tree').removeClass('in_edit_tree');
  var edit_tree = $(':focus').parents();
  // put little lines on teh right, to show the local heirarchy
  for (var i=0; i < edit_tree.length; ++i) {
      if (edit_tree[i].getAttribute('id') == "content") { break }
      edit_tree[i].classList.add('in_edit_tree')
  }
}, true);

// retrieve_previous_editing();
// console.log("retrieved previous", internalSource);

// make the top level menu
e_tree = current_editing["tree"];
console.log("e_tree", e_tree);
e_level = current_editing["level"];
console.log("e_level", e_level);
e_location = current_editing["location"];
console.log("e_location", e_location);
edit_menu_for(e_tree[e_level][e_location], "entering")

