
editorLog = console.log;
// editorLog = function(){};
debugLog = function(){};
// debugLog = console.log;
//parseLog = function(){};
parseLog = console.log;
errorLog = console.log;

/* the structure of each object, and its realization as PreTeXt source or in HTML,
   is recorded in the objectStructure dictionary.

{"xml:id": new_id, "sourcetag": new_tag, "parent": parent_description, "title": ""}

In pretext, pieces are of the form ["piecename", "tag"], while
in source, pieces are of the form ["piecename", "required_component"], while

*/

editing_mode = 0;

current_page = location.host+location.pathname;
debugLog("current_page", current_page);
chosen_edit_option_key = "edit_option".concat(current_page);
/*
chosen_edit_option = readCookie(chosen_edit_option_key) || "";
editing_mode = chosen_edit_option;
*/
chosen_edit_option = "PLACEHOLDER";
debugLog("chosen_edit_option", chosen_edit_option, "chosen_edit_option", chosen_edit_option > 0);

var prefs_menu_vals = {
    'avatar': {'cat': 'AA',
               'man': 'bb',
               'woman': 'CC'},
    'font': {'serif': 'SS',
             'sanserif': 'SSSS'},
    'mode': {'light': 'AA',
             'pastel': 'bb',
             'grey': 'bb',
             'dark': 'Dd'}
}

function choice_options(this_choice) {
    console.log("choice_options of", this_choice);
    val_dict = prefs_menu_vals[this_choice];
    console.log("val_dict", val_dict);
    var these_keys = Object.keys(val_dict);
    these_keys.sort();
    var these_choices = "";
    for (var j=0; j < these_keys.length; ++j) {
        this_key = these_keys[j];
        these_choices += '<li id="' + this_key + '">';
        these_choices += val_dict[this_key];
        these_choices += '</li>';
    }
    return these_choices
}

var sidebyside_instances = {
"sbs": [["2 panels", "sbs2"], ["3 panels", "sbs3"], ["4 panels", "sbs4"]],
//"sbs2": [["full across XX", "sbs2_0_50_50_0"], ["gap but no margin", "sbs2_0_40_40_0"], ["spaced equally", "sbs2_5_40_40_5"]],
"sbs2": [["full across", "sbs_0_50_50_0"], ["gap but no margin", "sbs_0_45_45_0"], ["spaced equally", "sbs_5_40_40_5"]],
"sbs3": [["full across", "sbs_0_34_32_34_0"], ["gap but no margin", "sbs_0_28_28_38_0"], ["spaced equally", "sbs_5_25_26_25_5"]],
"sbs4": [["full across", "sbs_0_25_25_25_25_0"], ["gap but no margin", "sbs_0_20_20_20_20_0"], ["spaced equally", "sbs_3_18_18_18_18_3"]]
}

// shoudl we distinguish empty tags by format?
var always_empty_tags = ["img", "image", "xref"];
// eventially xref will move to allowed_empty_tags
var allowed_empty_tags = ["div", "span", "p", "stack"];
var tag_display = {  /* the default is "block" */
    "inline": ["m", "em", "ellipsis", "span", "term", "dfn", "q", "c", "code", "alert", "nbsp", "xref", "idx", "h", "init"], 
    "title": ["title", "idx", "h1", "h2", "h3", "h4", "h5", "h6", "div", "usage", "image"],
    "block-tight": [] // ["mp", "mrow"]
} 

inline_tags = tag_display["inline"];
inline_math = ["m"];
inline_abbrev = ["ellipsis", "ie", "eg", "etc"];

// contained_objects are a componnet of another object, not just buried in content
var contained_objects =["title", "statement", "caption", "captiontext", "proof",
                        "author", "journal", "volume", "number", "pages"];

function tag_type(tag) {
    var this_type;

    if (["p", "ip", "mp", "fp"].includes(tag)) { this_type = "p" }
    else if (["me", "men", "md", "mdn"].includes(tag)) { this_type = "md" }
    else { this_type = tag }

    return this_type
}

function process_value_from_source(fcn, piece, src) {

    editorLog(fcn, "process_value_from_source", piece, "in", src);
    var content_raw = "";
    if (["literal", "codenumber", "period", "titleperiod", "space"].includes(fcn)) {
        content_raw = piece;
    } else {
        if (piece in src) {
          content_raw = src[piece]
        } else {
          if ("parent" in src) {
              var parent_src = internalSource[src["parent"][0]];
              if (piece in parent_src) {
                  content_raw = parent_src[piece]
              } else {
                  errorLog("Error: piece", piece, "fcn", fcn, "from", parent_src, "not in src or parent_src")
              }
          } else {
            errorLog("at the top, or else there is an error")
          }
        }
    } /* fcn != literal */

/*
    if (typeof myVar == 'string') {
        content_raw = content_raw.replace(/-standalone$/, "")  // hack because we need alternate to sourcetag
    }
*/
    if (fcn == "capitalize") {
        content = content_raw.charAt(0).toUpperCase() + content_raw.slice(1);
    } else if (fcn == "literal") {
        editorLog("literally", piece);
    //    alert(piece);
        content = piece
    } else if (fcn == "space") {
        content = content_raw + " "
    } else if (fcn == "period") {
        content = content_raw + "."
    } else if (fcn == "comma") {
        content = content_raw + ","
    } else if (fcn == "titleperiod") {
        if (src.title && !(/[!?]$/.test(src.title))) {
            content = content_raw + "."
        }
    } else if (fcn == "percentlist") {
        if (content_raw) {
            content = content_raw.join("% ") + "%"
        } else {
            content = "MISSING" + "%"
        }
    } else if (fcn == "nthitem") {

        editorLog("calculating nthitem", piece, "from ", content_raw, "within", src);
        var item_index = 0;  // need to be its location among siblings
        content = content_raw[item_index];
    } else if (fcn == "codenumber") {
        editorLog("   CODENUMBER", src);
        content = internalSource.root_data.number_base;
        if (src["xml:id"] == top_level_id) {
            // no need to add locan number
        } else {
            content += ".N"
        }
    } else {
         content = content_raw
    }

    return content
}

$(".autopermalink > a").attr("tabindex", -1);

var editable_objects = [["p", 99], ["ol", 97], ["ul", 96], ["article", 95], ["blockquote", 80], ["section", 66],
                        ["title", 20], ["caption", 890]];
for(var j=0; j < editable_objects.length; ++j) {
    $(editable_objects[j][0]).attr("data-editable", editable_objects[j][1]);
    $(editable_objects[j][0]).attr("tabindex", -1);
}

/* the code */

editorLog(" enabling edit");

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
var ongoing_editing_actions = [];
var old_content = {};   // to hold old versions of changed materials

// what will happen with internationalization?
var keyletters = ["KeyA", "KeyB", "KeyC", "KeyD", "KeyE", "KeyF", "KeyG", "KeyH", "KeyI", "KeyJ", "KeyK", "KeyL", "KeyM", "KeyN", "KeyO", "KeyP", "KeyQ", "KeyR", "KeyS", "KeyT", "KeyU", "KeyV", "KeyW", "KeyX", "KeyY", "KeyZ"];

var movement_location_options = [];
var movement_location = 0;
var first_move = true;  // used when starting to move, because object no longer occupies its original location

Storage.prototype.setObject = function(key, value) {
//    this.setItem(key, JSON.stringify(value));
    this.setItem(key, JSON.stringify(value, function(key, val) {
//    console.log("key", key, "value", value, "val", val);
    return val.toFixed ? Number(val.toFixed(3)) : val;
}));
}

Storage.prototype.getObject = function(key) {
    var value = this.getItem(key);
    return value && JSON.parse(value);
}

function randomstring(len) {
    if (!len) { len = 10 }
    return "tMP" + (Math.random() + 1).toString(36).substring(2,len)
}

function removeItemFromList(lis, value) {
  var index = lis.indexOf(value);
  if (index > -1) {
    lis.splice(index, 1);
  }
  return lis;
}

var submenu_options = {  // revise as these are handled previously
"math-like": [["me"], ["chem"], ["code"]],
"image-like": [["image"], ["video"], ["audio"]],
"aside-like": [["aside"], ["historical"], ["biographical"]],
"list-like": [["itemized list", "list"], ["dictionary list", "dl"], ["table"]],
"layout-like": [["side-by-side panels", "sbs"], ["assemblage"], ["biographical aside"], ["titled paragraph", "paragraphs"]],
"section-like": ["section", "subsection", "paragraphs", "rq", "exercises"],
"sbs": [["2 panels", "sbs2"], ["3 panels", "sbs3"], ["4 panels", "sbs4"]],
"list-like": [["itemized list", "list"], ["dictionary list", "dl"], ["table"]],
"example-like": ["example", "question", "problem"]
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
            ["display math/chemistry/code", "math-like", "c"],
            ["list or table", "list-like"],
            ["example-like", "example-like"],
            ["definition-like", "definition-like"],
            ["theorem-like", "theorem-like"],
            ["remark-like"],
            ["project/exercise-like", "project-like", "j"],
            ["image/video/sound", "image-like", "v"],
            ["blockquote/poem/music/etc", "quoted"],
            ["aside-like", "aside-like", "d"],
            ["interactives"],
            ["proof", "proof-standalone", "o"],
            ["layout-like"],
            ["section-like"],
    //        ["Save", "save"],
            ["PreTeXt source", "source"]],
  // need to unify section with paragraphs (when sections are managed by the CAT)
"paragraphs": [["paragraph", "p"],
            ["display math/chemistry/code", "math-like", "c"],
            ["list or table", "list-like"],
            ["example-like", "example-like"],
            ["definition-like", "definition-like"],
            ["theorem-like", "theorem-like"],
            ["remark-like"],
            ["project/exercise-like", "project-like", "j"],
            ["image/video/sound", "image-like", "v"],
            ["blockquote/poem/music/etc", "quoted"],
            ["aside-like", "aside-like", "d"],
            ["interactives"],
            ["proof", "proof-standalone", "o"],
            ["layout-like"],
   //         ["Save", "save"],
            ["PreTeXt source", "source"]],
"blockquote": [["paragraph", "p"]],
// "ol": [["list item", "li"]],
"article": [["paragraph", "p"],  //  this is for theorem-like and similar
            ["math/chemistry/code", "math-like", "c"],
            ["list or table", "list-like"],
            ["image/video/sound", "image-like", "v"]],
"li": [["new list item", "li", "i"],
            ["paragraph", "p"],
            ["list or table", "list-like"],
            ["math/chemistry/code", "math-like", "c"],
            ["image/video/sound", "image-like", "v"]],
"p": [["emphasis-like"], ["formula"], ["abbreviation"], ["symbol"], ["ref or link", "ref"]]
}
base_menu_for["proof"] = base_menu_for["article"];
base_menu_for["page"] = base_menu_for["section"];


// this should be created from inner_menu_for
editing_container_for = { "p": 1, "ip": 1, "mp": 1, "fp": 1,
 "theorem-like": ["theorem", "proposition", "lemma", "corollary", "claim", "fact", "identity", "algorithm"],
 "definition-like": ["definition", "conjecture", "axiom", "hypothesis", "principle", "heuristic", "assumption"],
"remark-like": ["remark", "warning", "note", "observation", "convention", "insight"],
"example-like": ["example", "question", "problem"],
"exercise-like": ["exercise"],
"ol": ["item"],
"li": [""],
"list": [""],
"image": [""],
"sbs2": [""],
"sbs3": [""],
"sbs4": [""],
"source": 1,
"proof-standalone": [""],  //just a guess
"proof": [""]  //just a guess
}

/*
var url = "https://github.com/oscarlevin/discrete-book/blob/master/ptx/sec_intro-intro.ptx";
editorLog("first here");
fetch(url)
  .then(function(data) {
    // Here you get the data to modify as you please
    editorLog("data", data)
    })
  .catch(function(error) {
    // If there is any error you will catch them here
    errorLog("there was an error")
  });
editorLog("then here");
*/

function menu_options_for(object_id, component_type, level) {
        // this should be a function of the object, not just its tag
        //  p in li vs p child of section, for example
     var menu_for;

     if (!component_type) { component_type = internalSource[object_id]["sourcetag"] }
     editorLog("component_tag", component_type);
     if (level == "base") {
         menu_for = base_menu_for
     } else if (level == "move-or-delete") {
         editorLog("C0 menu options for", component_type);
         var m_d_options;
         var component_parent = internalSource[object_id]["parent"][0];
         var component_parent_tag = internalSource[component_parent]["sourcetag"];
         if (component_type == "p" && component_parent_tag == "li") {
             m_d_options = [
                 ["move-local-p", "Move these words within this page"],
                 ["move-local-li", "Move this list item within this page"],
                 ["move-global", "Move this another page (not implemented yet)"],
                 ["delete", "Delete"]  // does it matter whether there are other p in this li?
             ];
         } else if(tag_type(component_type) == "p") {
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
             this_menu += '<li tabindex="-1" data-action="' + m_d_options[i][0] + '"';
             if (i==0) { this_menu += ' id="choose_topic"'}
             this_menu += '>';
             this_menu += m_d_options[i][1]
             this_menu += '</li>';
         }
         editorLog("made this_menu", this_menu);
         return this_menu
     } else if (level == "modify") {
         editorLog("CZ menu options for", component_type);
         var m_d_options;
         var component_parent = internalSource[object_id]["parent"][0];
         var component_parent_tag = internalSource[component_parent]["sourcetag"];
         if (component_type == "image") {
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
                 ["modify", "enlarge", "make this panel wider"],
                 ["modify", "shrink", "make this panel narrower"],
                 ["modify", "enlargeall", "make all panels wider"],
                 ["modify", "shrinkall", "make all panels narrower"],
                 ["modify", "leftminus", "decrease left margin"],
                 ["modify", "leftplus", "increase left margin"],
                 ["modify", "rightminus", "decrease right margin"],
                 ["modify", "rightplus", "increase right margin"],
                 ["modify", "done", "done modifying"]
             ];
         } else if (environment_instances["project-like"].includes(component_type) || component_type == "task") {
                     // needs to also include exercise-like
             m_d_options = [
                 ["modify", "enlarge", "more space"],
                 ["modify", "shrink", "less space"],
                 ["modify", "enlargeslightly", "slightly more space"],
                 ["modify", "shrinkslightly", "slightly less space"],
                 ["modify", "done", "done adjusting"]
             ];
         } else {
             alert("don;t know how to make that menu")
             m_d_options = []
         }
         var this_menu = "";
         for (var i=0; i < m_d_options.length; ++i) {
             this_menu += '<li tabindex="-1" data-action="' + m_d_options[i][0] + '" data-modifier="' + m_d_options[i][1] + '"';
             if (i==0) { this_menu += ' id="choose_topic"'}
             this_menu += '>';
             this_menu += m_d_options[i][2]
             this_menu += '</li>';
         }
         editorLog("made this_menu", this_menu);
         return this_menu
     } else if (level == "change") {
         editorLog("C1 menu options for", component_type);
         objectclass = objectStructure[component_type].owner;
         editorLog("which has class",objectclass);
         var equivalent_objects = environment_instances[objectclass].slice();
         var replacement_list = removeItemFromList(equivalent_objects, component_type);
         editorLog("equivalent_objects", equivalent_objects);
         var this_menu = "";
         for (var i=0; i < replacement_list.length; ++i) {
             this_menu += '<li tabindex="-1" data-action="change-env-to" data-env="' + replacement_list[i] + '"'; 
             if (i==0) { this_menu += ' id="choose_topic"'}
             this_menu += '>';
             this_menu += replacement_list[i];
             this_menu += '</li>';
         }
         editorLog("made this_menu", this_menu);
         return this_menu
  //   } else { menu_for = inner_menu_for() }
     } else { menu_for = submenu_options }
     editorLog("C2 in menu options for", component_type, "or", object_id);
     editorLog("menu_for", menu_for);
     if (component_type in menu_for) {
         component_items = menu_for[component_type]
     } else {
         // is this a reasonable default for what can go anywhere?
         editorLog("default menu for" + component_type);
         component_items = [["paragraph", "p"],
            ["math/chemistry/code", "math-like", "c"],
            ["list or table", "list-like"],
            ["image/video/sound", "image-like", "v"]]
     }

     this_menu = "";
     for (var i=0; i < component_items.length; ++i) {
         this_item = component_items[i];

         if (typeof this_item == "string") {
             this_item_name = this_item;
             this_item_label = this_item;
             this_item_shortcut = "";
         } else {  // list
             this_item_name = this_item[0];
             this_item_label = this_item_name;
             this_item_shortcut = "";
             if (this_item.length == 3) {
                 this_item_label = this_item[1];
                 this_item_shortcut = this_item[2];
             } else if (this_item.length == 2) { 
                 this_item_label = this_item[1];
             } 
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
         if (i==0) { this_menu += ' id="choose_topic"'}
         this_menu += '>';

         if (this_item_name.match(/^[a-z]/i)) {
             first_character = this_item_name.charAt(0);
             this_item_name = this_item_name.replace(first_character, "<b>" + first_character + "</b>");
         }

         this_menu += this_item_name 
                 // little right triangle if there is a submenu
  //       if (this_item_label in inner_menu_for()) { this_menu += '<div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div>' }
         if (this_item_label in submenu_options) { this_menu += '<div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div>' }
         this_menu += '</li>';
     }

     return this_menu
}

function top_menu_options_for(this_obj) {
    editorLog("top menu options for aa", this_obj);
    var this_id = this_obj.id;

// maybe the "classList" in this function shoudl instead look at the internalSource?

    var this_list = "";

    if (this_obj.classList.contains("heading")) {
        var this_obj_parent = this_obj.parentElement;
        editorLog("heading options for bbb", this_obj_parent); 
        var this_obj_parent_id = this_obj_parent.id;
        var this_obj_parent_source = internalSource[this_obj_parent_id];
        var this_obj_environment = this_obj_parent_source["sourcetag"];

        editorLog("this_obj_environment", this_obj_environment);
        
        this_list = '<li tabindex="-1" id="choose_topic" data-env="p" data-action="edit">Change the title</li>';
        this_list += '<li tabindex="-1" data-action="change-env">Change "' + this_obj_environment + '" to <div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div></li>';
    } else {
        var this_object_type = this_obj.tagName;   //  needs to examine other attributes and then look up a reasonable name
//consolidate this redundancy
        this_obj_id = this_obj.id;
        if (!this_obj_id) {
            this_obj_id=this_obj.getAttribute("data-parent_id")
            editorLog("now has id", this_obj_id);
        }
        this_obj_source = internalSource[this_obj_id];
        editorLog("this_obj_source", this_obj_source);
        editorLog("this_obj", this_obj, "classList", this_obj.classList, "T/F", this_obj.classList.contains("image-box"));
        this_obj_environment = this_obj_source["sourcetag"];
        if (this_object_type == "P" || this_obj.classList.contains("displaymath")) {  
            this_list = '<li tabindex="-1" id="choose_topic" data-env="p" data-action="edit">Edit ' + this_obj_environment + '</li>';
            var editable_children = next_editable_of(this_obj, "children");
            editorLog("editable_children", editable_children);
            if (editable_children.length  && !(this_object_type == "P")) {
                this_list += '<li tabindex="-1" data-env="' + this_object_type + '" data-location="enter">Enter ' + this_obj_environment + '</li>';
            }
            if (editable_children.length > 2 && (this_object_type == "SECTION")) {
                this_list += '<li tabindex="-1" data-env="' + this_object_type + '" data-location="end">Go to end of ' + this_obj_environment + '</li>';
            }
        } else if (this_obj.classList.contains("image-box")) {
            editorLog("found an image-box");
            this_list = '<li tabindex="-1" id="choose_topic" data-env="imagebox" data-action="modify">Modify layout<div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div></li>';
        } else if (this_obj.classList.contains("sbspanel")) {
            this_list = '<li tabindex="-1" id="choose_topic" data-env="sbspanel" data-action="modify">Modify layout<div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div></li>';
        } else {
            this_list += '<li tabindex="-1" id="choose_topic" data-env="' + this_object_type + '" data-location="enter">Enter ' + this_obj_environment + '</li>';
            if (this_object_type == "SECTION") {
                this_list += '<li tabindex="-1" data-env="' + this_object_type + '" data-location="end">Go to end of ' + this_obj_environment + '</li>';
            }
       }

        if (this_obj.classList.contains("sbspanel")) {
            this_list += '<li tabindex="-1" data-env="' + 'sbspanel' + '" data-location="afterbegin">Insert in panel<div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div></li>';
        }

        if (this_obj.classList.contains("project-like")) {
            this_list += '<li tabindex="-1" data-env="' + 'task' + '">Add a task</li>';
        }

        if (this_id != top_level_id) {
            this_list += '<li tabindex="-1" data-env="' + this_object_type + '" data-location="beforebegin">Insert before<div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div></li>';
            this_list += '<li tabindex="-1" data-env="' + this_object_type + '" data-location="afterend">Insert after<div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div></li>';

            this_list += '<li tabindex="-1" data-action="move-or-delete">Move or delete<div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div></li>';
        }
        this_list += '<li tabindex="-1" data-env="' + "metaadata" + '">Metadata<div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div></li>';
        if (this_id != top_level_id) {
            this_list += '<li tabindex="-1" data-env="' + "undo" + '">Revert<div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div></li>';
        }
        if (previous_editing() && this_id == top_level_id) {
            this_list += '<li tabindex="-1" data-action="' + "resume" + '">Resume previous editing</li>';
        }
        this_list += '<li tabindex="-1" data-action="' + "save" + '">Save</li>';
        this_list += '<li tabindex="-1" data-action="' + "stop_editing" + '">Stop editing</li>';
    }
    return this_list
}

function edit_menu_from_current_editing(motion) {
        // obviously we need to think a bit about current_editing and how it is used
    var object_of_interest = current_editing["tree"][ current_editing["level"] ][ current_editing["location"][ current_editing["level"] ] ];
    edit_menu_for(object_of_interest, motion);
}

function edit_menu_for(this_obj_or_id, motion) {
    editorLog("make edit menu", motion, "for", this_obj_or_id);

    // delete the old menu, if it exists
    if (document.getElementById('edit_menu_holder')) {
        var current_menu = document.getElementById('edit_menu_holder');
        editorLog("current_menu", current_menu);
        editorLog("this_choice", document.getElementById('enter_choice'));
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
        errorLog("error: empty this_obj_or_id", motion);
        return ""
    } else {
        editorLog("this_obj_or_id", this_obj_or_id, "string?", typeof this_obj_or_id === 'string');
        editorLog("which has parent", this_obj_or_id.parentElement)
    }

    if (typeof this_obj_or_id === 'string') {
        this_obj = document.getElementById(this_obj_or_id)
    } else {
        this_obj = this_obj_or_id
    }
    var this_id = this_obj.id;

    if (motion == "entering") {
        menu_location = "afterbegin";
        this_obj.classList.remove("may_leave"); 
        if (next_editable_of(this_obj, "children").length && !(this_obj.tagName == "P")) {
            this_obj.classList.add("may_enter");
        } else {
            this_obj.classList.add("may_select");
        }
        if (inline_tags.includes(this_obj.tagName.toLowerCase())) {
            this_obj.classList.add("inline");
        }
    } else { menu_location = "afterend";
        this_obj.classList.remove("may_select");
        this_obj.classList.remove("may_enter");
        this_obj.classList.add("may_leave"); 
        editorLog("added may_leave to", this_obj)
    }  // when motion is 'leaving'

    var edit_menu_holder = document.createElement('div');
    edit_menu_holder.setAttribute('id', 'edit_menu_holder');
    edit_menu_holder.setAttribute('tabindex', '-1');
    editorLog("adding menu for", this_obj_or_id, "menu_location", menu_location);
    editorLog("which has tag", this_obj.tagName);
    editorLog("does", this_obj.classList, "include type", this_obj.classList.contains("type"));

    this_obj.insertAdjacentElement(menu_location, edit_menu_holder);
    editorLog("added edit_menu_holder", document.getElementById("edit_menu_holder"), motion);

    var edit_option = document.createElement('span');
    edit_option.setAttribute('id', 'enter_choice');

    if (motion == "entering") {
        editorLog("inline_tags", inline_tags, "tag", this_obj.tagName.toLowerCase());
        editorLog("next_editable_of(this_obj, children)", next_editable_of(this_obj, "children"));
        if (false && inline_tags.includes(this_obj.tagName.toLowerCase())) {
            edit_option.innerHTML = "change this?";
            edit_option.setAttribute('data-location', 'inline');
        } else if (this_obj.classList.contains("type")) {
            // e.g., changing "proposition" to "theorem"
            // need to code this better:  over-writing edit_option
            edit_option = document.createElement('ol');
            edit_option.setAttribute('id', 'edit_menu');
            this_obj_parent_id = this_obj.parentElement.parentElement.id;
            this_obj_environment = internalSource[this_obj_parent_id]["sourcetag"];
            edit_option.innerHTML = '<li id="choose_topic" tabindex="-1" data-action="change-env">Change "' + this_obj_environment + '" to <div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div></li>';
            edit_option.setAttribute('data-location', 'inline');
        } else if (this_obj.classList.contains("image-box")) {
            edit_option.innerHTML = "<b>modify</b> this image layout, or add near here?";
        } else if (this_obj.classList.contains("sbspanel")) {
            edit_option.innerHTML = "<b>modify</b> this panel layout, or change panel contents?";
        } else if (this_obj.classList.contains("title") || this_obj.classList.contains("caption")) {
            var this_contained_type = "title";
            if (this_obj.classList.contains("caption")) { this_contained_type = "caption" }
            edit_option = document.createElement('ol');
            edit_option.setAttribute('id', 'edit_menu');
            editorLog("this_obj", this_obj);
            editorLog("this_obj.innerHTML", this_obj.innerHTML);
            editorLog("menu only?", this_obj.innerHTML == '<div id="edit_menu_holder" tabindex="-1"></div>');
            this_obj_parent_id = this_obj.parentElement.parentElement.id;
            this_obj_environment = internalSource[this_obj_parent_id]["sourcetag"];
            if (this_obj.innerHTML == '<div id="edit_menu_holder" tabindex="-1"></div>') {
                edit_option.innerHTML = '<li id="choose_topic" tabindex="-1" data-action="change-' + this_contained_type + '">Add a ' + this_contained_type + '</li>';
            } else {
                edit_option.innerHTML = '<li id="choose_topic" tabindex="-1" data-action="change-' + this_contained_type + '">Change ' + this_contained_type + '</li>';
            }
            edit_option.setAttribute('data-location', 'inline');
        } else if ((this_obj.classList.contains("placeholder") && (this_obj.classList.contains("hint") ||
                  this_obj.classList.contains("answer") ||
                  this_obj.classList.contains("solution") ||
                  this_obj.classList.contains("proof")) ) ) {
            var theverb = "add"
            var thenoun = this_obj.getAttribute("data-HAS");
            edit_option.setAttribute('id', 'choose_topic');
            edit_option.setAttribute('data-env', thenoun);
            edit_option.setAttribute('data-parent_id', this_obj.getAttribute("data-parent_id"));
            edit_option.innerHTML = "<b>" + theverb + "</b>" + " " + thenoun;
        } else if (this_obj.classList.contains('workspace')) {
            edit_option.setAttribute('id', 'choose_topic');
            edit_option.setAttribute('data-env', 'workspace');
            edit_option.setAttribute('data-action', 'modify');
            edit_option.setAttribute('data-parent_id', this_obj.getAttribute("data-parent_id"));

            edit_option.innerHTML = "<b>" + "adjust" + "</b>" + " " + "workspace";
        } else {
            if (next_editable_of(this_obj, "children").length && this_obj.tagName != "P") {
                editorLog("this_obj", this_obj);
                if (this_id == top_level_id) {
                    edit_option.innerHTML = "<b>enter</b> this " + internalSource[this_obj.id]["sourcetag"] + "?";
                } else {
                    edit_option.innerHTML = "<b>enter</b> this " + internalSource[this_obj.id]["sourcetag"] + ", or add near here?";
                }
            } else {
                edit_option.innerHTML = "<b>edit</b> this passage, or add near here?";
            }
            edit_option.setAttribute('data-location', 'next');
        }
    } else {
        edit_option.setAttribute('data-location', 'stay');
        edit_option.innerHTML = "continue editing this " + internalSource[this_obj.id]["sourcetag"];
    }
    editorLog("edit_option", edit_option);
    document.getElementById("edit_menu_holder").insertAdjacentElement("afterbegin", edit_option);
    document.getElementById('edit_menu_holder').focus();
}

function next_editable_of(obj, relationship) {
    var next_to_edit;
    editorLog("finding", relationship, "editable of", obj);
    if (relationship == "children") {
        next_to_edit = $(obj).find(' > [data-editable], > .sidebyside > .sbsrow > [data-editable],  > li > [data-editable], > .heading > [data-editable], > .hint > [data-editable], > .answer > [data-editable]')
    } else if (relationship == "outer-block") {  // for example, a direct child of a section
        next_to_edit = $(obj).find(' > [data-editable]')
    } else if (relationship == "inner-block") {  // typically a paragraph
        next_to_edit = $(obj).find('section > [data-editable], [data-editable="99"], [data-editable="42"]')
    } else if (relationship == "li-only") {  // typically a paragraph
        next_to_edit = $(obj).find('li')
    } else {
        editorLog("unimplemented next_editable_of")
    }

    editorLog("next_to_edit", next_to_edit);
    return next_to_edit
}

function create_local_menu() {

// this does not work, but local menu navigator would not have worked either

            editorLog("make local edit menu for", this_obj_id);
            var local_menu_holder = document.createElement('div');
            local_menu_holder.setAttribute('id', 'local_menu_holder');
            local_menu_holder.setAttribute('tabindex', '-1');
            editorLog("adding local menu for", this_obj_id);
            document.getElementById(this_obj_id).insertAdjacentElement("afterbegin", local_menu_holder);

            var enter_option = document.createElement('ol');
            enter_option.setAttribute('id', 'edit_menu');

            enter_option.innerHTML = menu_options_for(this_obj_id, "XunusedX", "base");

            document.getElementById("local_menu_holder").insertAdjacentElement("afterbegin", enter_option);

}

function local_editing_action(e) {
    editorLog("in local editing action for" ,e.code);
    var most_recent_edit;
    if (e.code == "Escape" || e.code == "Enter") {
        editorLog("I saw a Rettttt");
        if (document.activeElement.getAttribute('data-component') == "title" ||
            document.activeElement.getAttribute('data-component') == "caption") {
            editorLog("probably saving a ", document.activeElement.getAttribute('data-component'));
            e.preventDefault();
            these_changes = assemble_internal_version_changes(document.activeElement);
            final_added_object = insert_html_version(these_changes);
            most_recent_edit = ongoing_editing_actions.pop();
            recent_editing_actions.unshift(most_recent_edit);
            editorLog("most_recent_edit should be title change", most_recent_edit);
            editorLog("final_added_object", final_added_object);
            this_char = "";
            prev_char = "";
            save_edits();

            // .title is in a .heading, and neither have an id
            make_current_editing_tree_from_id(final_added_object.parentElement.parentElement.id);
            edit_menu_from_current_editing("entering");

// editing_input_image
        } else if (e.code == "Escape" || (prev_char.code == "Enter" && prev_prev_char.code == "Enter") || document.getElementById("editing_input_image")) {
            editorLog("need to save");
editorLog("    HHH current_editing", current_editing, "with active element", document.activeElement);

            e.preventDefault();
            this_char = "";
            prev_char = "";
            these_changes = assemble_internal_version_changes(document.activeElement);
            editorLog("    CCC these_changes", these_changes);
            editorLog("    CCC0 these_changes[0]", these_changes[0]);
            editorLog("ongoing_editing_actions", ongoing_editing_actions);
            editorLog("actively_editing", document.getElementById("actively_editing"));
editorLog("    III current_editing", current_editing, current_editing["tree"][current_editing["level"]]);
            previous_added_object = final_added_object;
            final_added_object = insert_html_version(these_changes);
            editorLog("final_added_object, previous_added_object", final_added_object, previous_added_object);
editorLog("    LLL current_editing", current_editing, current_editing["tree"][current_editing["level"]]);
            editorLog("the final_added_object", final_added_object);
            editorLog("the actively_editing", document.getElementById("actively_editing"));
            editorLog("OO", ongoing_editing_actions.length, " ongoing_editing_actions", ongoing_editing_actions);
/*
            editorLog("ongoing_editing_actions[0]", ongoing_editing_actions[0]);
            editorLog("ongoing_editing_actions[0][2]", ongoing_editing_actions[0][2]);
*/
                // maybe this next if only handles when we delete by removing the letters in a p?
            if (these_changes[0] == "empty") {
                editorLog("NN", ongoing_editing_actions.length, " ongoing_editing_actions", ongoing_editing_actions);
                editorLog("ongoing_editing_actions[0]", ongoing_editing_actions[0]);
                editorLog("ongoing_editing_actions[0][2]", ongoing_editing_actions[0][2]);
                editorLog("            going to delete", these_changes[2][0]);
                // this is sort-of a hack to detext the end of inserting li
                if (ongoing_editing_actions.length == 2 &&
                    ongoing_editing_actions[1][0] == "empty" &&
                    ongoing_editing_actions[1][1] == "p" &&
                    ongoing_editing_actions[0][0] == "new" &&
                    ongoing_editing_actions[0][1] == "li") {
                    ongoing_editing_actions.pop();   // content was empty, so there is no editing action
                    ongoing_editing_actions.pop();
                    delete_by_id(these_changes[2][0][0], "newempty");
                    current_editing["location"][current_editing["level"]] -= 1
                    final_added_object = previous_added_object;  // this approach makes the updating of current_editing moot?
                } else {
                    delete_by_id(these_changes[2][0][0], "empty");
                }
                editorLog("MM", ongoing_editing_actions.length, " ongoing_editing_actions", ongoing_editing_actions);
                for (var j=0; j<ongoing_editing_actions.length; ++j ) {
                    editorLog(j, "ongoing_editing_actions[j]", ongoing_editing_actions[j]);
                }
                editorLog("PP", ongoing_editing_actions.length, " ongoing_editing_actions", ongoing_editing_actions);
            }
            if (final_added_object) { //  && document.getElementById("actively_editing")) 

              if(document.getElementById("actively_editing")) {
editorLog("    SSS current_editing", current_editing, current_editing["tree"][current_editing["level"]]);

                var editing_placeholder = document.getElementById("actively_editing");
                editorLog("still editing", editing_placeholder, "which contains", final_added_object);
                var this_parent = internalSource[final_added_object.id]["parent"];
                editorLog("final_added_object parent", this_parent);
                var the_whole_object = html_from_internal_id(this_parent[0]);
                editorLog("the_whole_object", the_whole_object);
                if (internalSource[this_parent[0]]["sourcetag"] == "proof") { // insert the theorem-like statement
                    alert("something about a proof");
                    var the_parent_object = html_from_internal_id(internalSource[this_parent[0]]["parent"][0]);
                    the_whole_object = the_parent_object.concat(the_whole_object)
                }
                for (var j = the_whole_object.length - 1; j >= 0; --j) {
                    editorLog("   X", j, "the_whole_object[j]", the_whole_object[j]);
                    document.getElementById("actively_editing").insertAdjacentElement("afterend", the_whole_object[j])
                    MathJax.typesetPromise();
         //           MathJax.Hub.Queue(['Typeset', MathJax.Hub, the_whole_object[j]]);
                }
                
                editorLog("here is where we need to update current_editing", "parent:", this_parent,"which is",document.getElementById(this_parent[0]), "level:", current_editing["level"], "loation:", current_editing["location"], "tree:", current_editing["tree"]);
                $("#actively_editing").remove();

editorLog("    DDD current_editing", current_editing, current_editing["tree"][current_editing["level"]]);

              }

              most_recent_edit = ["","",""];
              while (ongoing_editing_actions.length) {
                  most_recent_edit = ongoing_editing_actions.pop();
                  recent_editing_actions.unshift(most_recent_edit);
                  editorLog("      most_recent_edit", most_recent_edit);
              }
              editorLog("     8888 final_added_object", final_added_object);

              save_edits()

              // is this in the right place?
              editorLog("most_recent_edit", most_recent_edit);

              // sometimes, such as when adding items to a list, you want to
              // automatically start adding something else.
              // maybe refactor theorem to add proof after?
              if (most_recent_edit[1] == "li") {  // added to a list, so try adding again
                    //  note that when adding an li, the neichbor is a p within the actual li neighbor
                  var new_obj = create_object_to_edit("li", document.getElementById(most_recent_edit[2]).firstElementChild, "afterend")
                  edit_in_place(new_obj, "new");
                  editorLog("now editing the assumed new li");
editorLog("    GGG current_editing", current_editing, current_editing["tree"][current_editing["level"]]);

              } else {

                  editorLog("re-making the tree from final_added_object", final_added_object);
                  make_current_editing_tree_from_id(final_added_object.id);
                  editorLog("and then adding a menu");
                  edit_menu_from_current_editing("entering");
              }

            } else if ( document.getElementById("actively_editing")) {
                document.getElementById("actively_editing").remove();
                // were actively editing, and now just re-making the menu
                edit_menu_from_current_editing("entering");
            } else {
                // default makng the menu
                edit_menu_from_current_editing("entering");
            }   
        }  //  esc or enter enter enter
        editorLog ("processed an enter");
    } //  esc or enter
      else {
        editorLog("e.code was not one of those we were looking for", e)
    }
    editorLog("leaving local editing action")
}

function main_menu_navigator(e) {  // we are not currently editing
                              // so we are building the menu, and possibly moving aroung the document,
                              //for the user to decide what/how to edit

// There are 3 modes:
//   #enter_choice, data-location="next"
//   #enter_choice, data-location="stay"
// above means we are deciding whenter to edit/enter/leave and object, or to move on
//   #choose_topic
// 3rd option means we already have a menu

    console.log("entered main_menu_navigator");

    if(!document.getElementById("preferences_menu_holder")) {
        var prefs_button = document.getElementById("user-preferences-button");

        var preferences_menu_holder = document.createElement('div');
        preferences_menu_holder.setAttribute('id', 'preferences_menu_holder');
        preferences_menu_holder.setAttribute('tabindex', '-1');

        prefs_button.insertAdjacentElement("afterend", preferences_menu_holder);

        var main_menu = '<ol>';
        main_menu += '<li id="choose_topic" data-env="avatar">Choose avatar</li>';
        main_menu += '<li data-env="font">Adjust font</li>';
        main_menu += '<li data-env="mode">Select dark/light mode</li>';
        main_menu += '</ol>';
        preferences_menu_holder.innerHTML = main_menu;
    } else if (document.getElementById("choose_topic")) {
        theChooseTopic = document.getElementById("choose_topic");
        console.log("theEnterChoice", theChooseTopic);
        console.log("choose_topic", e);
        var theEnv = theChooseTopic.getAttribute("data-env");
        console.log("theEnv",theEnv);
        console.log("next options",choice_options(theEnv));

        var choice_menu_holder = document.createElement('ol');
        theChooseTopic.insertAdjacentElement("beforeend", choice_menu_holder);
        choice_menu_holder.innerHTML = choice_options(theEnv);

        if ((e.code == "Tab" || e.code == "ArrowDown") && !e.shiftKey) {
            e.preventDefault();
            if (current_level == 0) { // at the top, so no "next" object
                return ""
            }
            // go to next sibling, or stage to exit if on last sibling
            if (current_location == (current_siblings.length - 1)) { // on last sibling
                    editorLog("on last sibling, level was", current_level,"siblings was", current_siblings, "tree", current_editing["tree"]);
                    editorLog("current_location was", current_location);
                    current_level -= 1;
                    current_location = current_editing["location"][current_level];
                    current_editing["level"] = current_level;
                    current_editing["location"][current_level] = current_location;
                    current_siblings = current_editing["tree"][current_level];
                    editorLog("current_location is", current_location);
                    editorLog("stay menu A");
                    object_of_interest.classList.remove("may_leave");
                    object_of_interest.classList.remove("may_elect");
                    edit_menu_from_current_editing("leaving")
            } else {
                editorLog("moving to the next editable sibling");
                    editorLog("level was", current_level,"siblings was", current_siblings, "tree", current_editing["tree"]);
                    editorLog("current_location was", current_location);
                editorLog(current_location, "was", current_editing);
                current_location += 1;
                object_of_interest.classList.remove("may_leave");
                object_of_interest.classList.remove("may_elect");
                    editorLog("current_location is", current_location);
              editorLog("stay menu B");
                current_editing["location"][current_level] = current_location;
                editorLog(current_location, "is", current_editing);
                edit_menu_from_current_editing("entering")
            }
        } else if ((e.code == "Tab" && e.shiftKey) || e.code == "ArrowUp") {  // Shift-Tab to prevous object
            e.preventDefault();
            // go to previous sibling, or up one if on first sibling
            editorLog("Arrow Up:", "current_location", current_location, "current_level", current_level);
            if (theMotion == "stay") {  // about to leave, to return to the top of that region
                edit_menu_from_current_editing("entering")
            } else if (current_location == 0) {
                if (!current_level) { // already at the top, so nowhere to go, so do nothing
                    editorLog("at the top, so can't go up");
                    return ""
                }
                current_level -= 1;
                current_editing["level"] = current_level;
                current_location = current_editing["location"][current_level];
                editorLog("AA new current_location", current_location, " current_editing['tree']",  current_editing["tree"]);
                editorLog(" current_editing['tree'][0]",  current_editing["tree"][0]);
                current_siblings = current_editing["tree"][current_level];
                editorLog("current_siblings", current_siblings);
                edit_menu_from_current_editing("entering")
            } else {
                current_location -= 1;
                current_editing["location"][current_level] = current_location;
                editorLog("current_siblings", current_siblings);
                editorLog("BB new current_location", current_location, "at level", current_level, " current_editing['tree']",  current_editing["tree"]);
                edit_menu_from_current_editing("entering")
            }
        } else if (e.code == "Escape" || e.code == "ArrowLeft") {
            e.preventDefault();
            if (current_level == 0) { return "" } // already at the top, so nowhere to go, so do nothing
// copied from A1
            editorLog("At ArrowLeft, level was", current_level, "with location",  current_editing["location"], "and tree", current_editing["tree"][current_level]);
            current_level -= 1;
            current_editing["level"] = current_level;
            current_location = current_editing["location"][current_level];
            current_siblings = current_editing["tree"][current_level];
            editorLog("now level id", current_level, "with location",  current_editing["location"], "and tree", current_editing["tree"][current_level]);
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
            editorLog("to_be_edited", to_be_edited);
            edit_submenu.innerHTML = top_menu_options_for(to_be_edited);
            $("#enter_choice").replaceWith(edit_submenu);
            document.getElementById('choose_topic').focus();
        }
        editorLog("   Just handled the case of enter_choice");
        return ""

    } else if (document.getElementById("choose_topic")) {
        var theChooseCurrent = document.getElementById("choose_topic");
        var dataLocation = theChooseCurrent.getAttribute("data-location");  // may be null
        var dataAction = theChooseCurrent.getAttribute("data-action");  // may be null
        var dataModifier = theChooseCurrent.getAttribute("data-modifier");  // may be null
        var dataEnv = theChooseCurrent.getAttribute("data-env");  // may be null
        // a hack because of how the menus were originally set up
        if (dataEnv == "save") { dataAction = "save" }
        var dataEnvParent = theChooseCurrent.getAttribute("data-env-parent");  // may be null
        var object_of_interest;
        if (document.getElementById("edit_menu_holder")) {
            object_of_interest = document.getElementById("edit_menu_holder").parentElement
        } else if (document.getElementById("local_menu_holder")) {
            object_of_interest = document.getElementById("local_menu_holder").parentElement
        } else {
            editorLog("something is confused:  should be a menu, but isn't");
            if (theChooseCurrent.id) {
                make_current_editing_tree_from_id(theChooseCurrent.id);
                object_of_interest = theChooseCurrent
            } else {
                make_current_editing_tree_from_id(theChooseCurrent.parentElement.id);
                object_of_interest = theChooseCurrent.parentElement
            }
            editorLog("made entering menu for", object_of_interest);
            edit_menu_from_current_editing("entering")
        }
        current_level = current_editing["level"];
        current_location = current_editing["location"][current_level];
        current_siblings = current_editing["tree"][current_level];
        editorLog("in choose_topic", dataLocation, "of", object_of_interest);
        editorLog("dataAction ", dataAction);
        editorLog("dataLocation ", dataLocation);
          // we have an active menu, and have selected an item
          // there are three main sub-cases, depending on whether there is a data-location attribute,
          // a data-action attribute, or a data-env attribute.
          // That is the primary order in which those attributes are considered
          // however, some actions (such as Tab and shift-Tab) are the same
          // in each sub-case (because all we are doing is moving up and down the
          // current list of options), so we handle those first.

        if ((e.code == "Tab" || e.code == "ArrowDown") && !e.shiftKey) {
            e.preventDefault();
            next_menu_item = theChooseCurrent.nextSibling;
            editorLog("theChooseCurrent", theChooseCurrent, "next_menu_item", next_menu_item);
            if (!next_menu_item) { next_menu_item = theChooseCurrent.parentNode.firstChild }
            editorLog("theChooseCurrent", theChooseCurrent, "next_menu_item", next_menu_item);
            if (theChooseCurrent == next_menu_item) { //only one item on menu, so Tab shold move to the next editable item
                // if last editable child, go up one
                if (current_location == (current_siblings.length - 1)) { 
                    current_level -= 1;
                    current_location = current_editing["location"][current_level];
                    current_editing["level"] = current_level;
                    current_editing["location"][current_level] = current_location;
                    edit_menu_from_current_editing("leaving")
                } else {
                    current_location += 1;
                    editorLog("single item menu, current_location now", current_location);
                    current_editing["location"][current_level] = current_location;
                    edit_menu_from_current_editing("entering");
                }
            }
            theChooseCurrent.removeAttribute("id");
            editorLog("theChooseCurrent", theChooseCurrent, "next_menu_item", next_menu_item);
            next_menu_item.setAttribute("id", "choose_topic");
            editorLog("setting focus on",next_menu_item);
            next_menu_item.focus();
        }  // Tab
          else if ((e.code == "Tab" && e.shiftKey) || e.code == "ArrowUp") {  // Shift-Tab to prevous object
            e.preventDefault();
            editorLog("just saw a", e.code);
            editorLog("focus is on", $(":focus"));
            editorLog("saw an",e.code);
            next_menu_item = theChooseCurrent.previousSibling;
            editorLog("W1 theChooseCurrent", theChooseCurrent, "next_menu_item", next_menu_item);
            if (!next_menu_item) { next_menu_item = theChooseCurrent.parentNode.lastChild }
            editorLog("W2 theChooseCurrent", theChooseCurrent, "next_menu_item", next_menu_item);
            if (theChooseCurrent == next_menu_item) { //only one item on menu, so Shift-Tab shold move to previous or up one level
                if (current_editing["location"][ current_editing["level"] ] == 0) {
                    current_editing["level"] -= 1;
                } else {
                    current_editing["location"][ current_editing["level"] ] -= 1;
                }
                editorLog("single item menu, current_level now", current_level);
                edit_menu_from_current_editing("entering");
            } else {
                theChooseCurrent.removeAttribute("id");
                editorLog("W3 theChooseCurrent", theChooseCurrent, "next_menu_item", next_menu_item);
                theChooseCurrent.classList.remove("chosen");
                next_menu_item.setAttribute("id", "choose_topic");
                editorLog("setting focus on",next_menu_item);
                next_menu_item.focus();
            }
        }
          else if (e.code == "Escape" || e.code == "ArrowLeft") {
            editorLog("processing ESC");
            editorLog("At ArrowLeft, level was", current_level, "xx", current_editing["level"], "with location",  current_editing["location"], "and tree", current_editing["tree"][current_level]);
   // I think the next if can never be true, because of how to route keystrokes
            if (document.getElementById("local_menu_holder")) {  // hack for when the interface gets confused
                document.getElementById("local_menu_holder").remove()
            } else {
                editorLog("W4 theChooseCurrent", theChooseCurrent);
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
                    previous_menu_item.setAttribute("id", "choose_topic");
                    previous_menu_item.focus();
                }
            }
      }
        else if (keyletters.includes(e.code)) {
          key_hit = e.code.toLowerCase().substring(3);  // remove forst 3 characters, i.e., "key"
          editorLog("key_hit", key_hit);
          theChooseCurrent = document.getElementById('choose_topic');
          editorLog('theChooseCurrent',  theChooseCurrent );
          editorLog( $(theChooseCurrent) );
            // there can be multiple data-jump, so use ~= to find if the one we are looking for is there
            // and start from the beginning in case the match is earlier  (make the second selector better)
          if ((next_menu_item = $(theChooseCurrent).nextAll('[data-jump~="' + key_hit + '"]:first')[0]) ||
              (next_menu_item = $(theChooseCurrent).prevAll('[data-jump~="' + key_hit + '"]:last')[0])) {  // check there is a menu item with that key
              theChooseCurrent.removeAttribute("id", "choose_topic");
              next_menu_item.setAttribute("id", "choose_topic");
              next_menu_item.focus();
          } else {
              // not sure what to do if an irrelevant key was hit
              editorLog("that key does not match any option")
          }
      }

//  Now only Enter and ArrowRight are meaningful in this context.
//  The effect will depend on the other attributes of #choose_topic:
//  dataLocation, dataAction, dataEnv

      else if (e.code == "Enter" || e.code == "ArrowRight") {
        e.preventDefault();
        if (dataLocation) {
            if (dataLocation == "enter") {  // we are moving down into an object

                editorLog("theChooseCurrent", theChooseCurrent);
                var object_to_be_entered = object_of_interest;
                editorLog("object_to_be_entered", object_to_be_entered);
                object_to_be_entered.classList.remove("may_select");
                object_to_be_entered.classList.remove("may_enter");
                object_to_be_entered.classList.remove("may_leave");
                editorLog('next_editable_of(object_to_be_entered, "children")');
                editableChildren = next_editable_of(object_to_be_entered, "children");
                current_level += 1;
                current_editing["level"] = current_level;
                current_editing["location"][current_level] = 0;
                current_editing["tree"][current_level] = editableChildren;
                editorLog("current_editing", current_editing);

                editorLog("object_to_be_entered", object_to_be_entered);
                editorLog("with some children", editableChildren);
               // put  menu on the item at the top of the block_we_are_reentering
                   // this is a repeat of a Tab case, so consolidate
                editorLog("menu place 10");
                editorLog("document.activeElement", document.activeElement);

                 editorLog("menu on", editableChildren[0]);
                 edit_menu_for(editableChildren[0], "entering");

                return ""
             // combine the next with previous, because the ony difference is which object receives focus
            } else if (dataLocation == "end") {  // move to the end of an object

                editorLog("theChooseCurrent", theChooseCurrent);
                var object_to_be_entered = object_of_interest;
                editorLog("object_to_be_entered", object_to_be_entered);
                object_to_be_entered.classList.remove("may_select");
                object_to_be_entered.classList.remove("may_enter");
                object_to_be_entered.classList.remove("may_leave");
                editorLog('next_editable_of(object_to_be_entered, "children")');
                editableChildren = next_editable_of(object_to_be_entered, "children");
                var num_editableChildren = editableChildren.length;
                current_level += 1;
                current_editing["level"] = current_level;
    //            current_editing["location"][current_level] = 0;
                current_editing["location"][current_level] = num_editableChildren - 1;
                current_editing["tree"][current_level] = editableChildren;
                editorLog("current_editing", current_editing);

                editorLog("object_to_be_entered", object_to_be_entered);
                editorLog("with some children", editableChildren);
               // put  menu on the item at the top of the block_we_are_reentering
                   // this is a repeat of a Tab case, so consolidate
                editorLog("menu place 10end");
                editorLog("document.activeElement", document.activeElement);

                 editorLog("menu on", editableChildren[num_editableChildren - 1]);
                 edit_menu_for(editableChildren[num_editableChildren - 1], "entering");

                return ""
            } else if ((dataLocation == "beforebegin") || (dataLocation == "afterend") || (dataLocation == "afterbegin")) {  // should be the only other options
                theChooseCurrent.parentElement.classList.add("past");
                theChooseCurrent.removeAttribute("id");
                theChooseCurrent.classList.add("chosen");

                var parent_id = document.getElementById('edit_menu_holder').parentElement.parentElement.id;
                if (!parent_id) {
                    editorLog(document.getElementById('edit_menu_holder').parentElement.parentElement, "has no id, so going down one level");
                    parent_id = document.getElementById('edit_menu_holder').parentElement.id;
                }
                editorLog("making a menu for", parent_id);
                var edit_submenu = document.createElement('ol');
                edit_submenu.innerHTML = menu_options_for(parent_id, "", "base");
                editorLog("just inserted inner menu_options_for(" + parent_id + ")", menu_options_for(parent_id, "", "base"));
                theChooseCurrent.insertAdjacentElement("beforeend", edit_submenu);
                document.getElementById('choose_topic').focus();
                editorLog("focus is on", $(":focus"));

                return ""
            } else {
                editorLog("Error: unknown dataLocation:", dataLocation)
            }
        }  // dataLocation

          else if (dataAction) {
            if (dataAction == "edit") {
                editorLog("going to edit", object_of_interest);
                edit_in_place(object_of_interest, "old");
            } else if (dataAction == "replace") {  // no longer used?
                editorLog("replace", object_of_interest, "by id", object_of_interest.id);
                replace_by_id(object_of_interest.id, "html")
            } else if (dataAction == "stop_editing") {
                editorLog("stop_editing", object_of_interest, "by id", object_of_interest.id);
                replace_by_id(object_of_interest.id, "html")
                eraseCookie(chosen_edit_option_key)
            } else if (dataAction == "save") {
                save_source();
                edit_menu_from_current_editing("entering");
            } else if (dataAction == "resume") {
                editorLog("resuming previous editing session");
                resume_editing()
            } else if (dataAction == "change-env-to") {
                 // shoudl use dataEnv ?
                var new_env = theChooseCurrent.getAttribute("data-env");
                editorLog("changing environment to", new_env);
                       // #edit_menu_holder is in span.type, inside .heading, inside article
                to_be_edited = document.getElementById('edit_menu_holder').parentElement.parentElement.parentElement;
                editorLog("to_be_edited", to_be_edited);
                var id_of_object = to_be_edited.id;
                var this_object_source = internalSource[id_of_object];
                editorLog("current envoronemnt", this_object_source);
                var old_env = internalSource[id_of_object]["sourcetag"];
                internalSource[id_of_object]["sourcetag"] = new_env;
                recent_editing_actions.push([old_env, new_env, id_of_object]);
                editorLog("the change was", "changed " + old_env + " to " + new_env + " " + id_of_object);
                var the_whole_object = html_from_internal_id(id_of_object);
                editorLog("B: the_whole_object", the_whole_object);
                $("#" + id_of_object).replaceWith(the_whole_object[0]);  // later handle multiple additions
                editorLog("just edited", $("#" + id_of_object));
                // since we changed an object which is in 
                editorLog("curent_editing level", current_editing["level"], "with things", current_editing["tree"][current_editing["level"]]);
                current_editing["level"] -= 1;
                current_editing["tree"][current_editing["level"]] = next_editable_of(document.getElementById(id_of_object).parentElement, "children");
                editorLog("now curent_editing level", current_editing["level"], "with things", current_editing["tree"][current_editing["level"]]);
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
                editorLog("J1 lookinh for menu options for", current_env_id);
                edit_submenu.innerHTML = menu_options_for(current_env_id, "", "change");
                editorLog("just inserted inner menu_options_for(parent_type)", menu_options_for(current_env_id, "", "change"));
                theChooseCurrent.insertAdjacentElement("beforeend", edit_submenu);
                document.getElementById('choose_topic').focus();
                editorLog("focus is on", $(":focus"));
            } else if (dataAction == 'modify') {
                       // #edit_menu_holder is in span.type, inside .heading, inside article
                    current_env = document.getElementById('edit_menu_holder').parentElement;
                    current_env_id = current_env.id;

                    if (!dataModifier) {
                        theChooseCurrent.parentElement.classList.add("past");
                        theChooseCurrent.removeAttribute("id");
                        theChooseCurrent.classList.add("chosen");

                        var edit_submenu = document.createElement('ol');
                           // this may only hapen when adjusting workspace:
                        if (!current_env_id) {
                            edit_submenu.setAttribute('id', 'edit_menu');
                            current_env_id = current_env.getAttribute("data-parent_id");
                            editorLog("current_env_id", current_env_id);
                        }
                        editorLog("J2a looking for menu options for", current_env_id);
                        edit_submenu.innerHTML = menu_options_for(current_env_id, "", "modify");
                        editorLog("just inserted inner menu_options_for(parent_type)", menu_options_for(current_env_id, "", "modify"));
                        if (theChooseCurrent.tagName == "SPAN") {  // when adjusting workspace
                            theChooseCurrent.replaceWith(edit_submenu);
                        } else {
                            theChooseCurrent.insertAdjacentElement("beforeend", edit_submenu);
                        }
                        document.getElementById('choose_topic').focus();
                        editorLog("focus is on", $(":focus"));
                    } else if (dataModifier == "done") {
                        edit_menu_from_current_editing("entering");
                    } else if (dataModifier == "arrows") {
                        // setup_arrow_modify()   // is different for images and SBSs
                    } else {
                           // this may only hapen when adjusting workspace:
                        if (!current_env_id) {
                            current_env_id = current_env.getAttribute("data-parent_id");
                            editorLog("current_env_id from parent", current_env_id);
                        }
                        modify_by_id(current_env_id, dataModifier)
                    }
            } else if (dataAction == "move-or-delete") {
                // almost all repeats from dataAction == 'change-env' 
                //  except for current_env and menu options for.  Consolidate
                //  maybe also separate actions which give anotehr menu, from actions which change content
                current_env = document.getElementById('edit_menu_holder').parentElement;
                editorLog("current_env", current_env);
                current_env_id = current_env.id;

                theChooseCurrent.parentElement.classList.add("past");
                theChooseCurrent.removeAttribute("id");
                theChooseCurrent.classList.add("chosen");

                var edit_submenu = document.createElement('ol');
                editorLog("J3 looking for menu options for", current_env_id);
                edit_submenu.innerHTML = menu_options_for(current_env_id, "", "move-or-delete");
                editorLog("just inserted inner menu_options_for(parent_type)", menu_options_for(current_env_id, "", "move-or-delete"));
                theChooseCurrent.insertAdjacentElement("beforeend", edit_submenu);
                document.getElementById('choose_topic').focus();
                editorLog("focus is on", $(":focus"));
            } else if (dataAction == "delete") {
                current_env = document.getElementById('edit_menu_holder').parentElement;
                editorLog("current_env", current_env);
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
                editorLog("current_env", current_env);
                move_by_id_local(current_env_id, handle_env_id)
            } else if (dataAction == "change-title") {
                var this_heading = document.getElementById('edit_menu_holder').parentElement.parentElement;
                var this_env_id = this_heading.getAttribute("data-parent_id");
                var new_title_form = standard_title_form(this_env_id);
                document.getElementById('edit_menu_holder').parentElement.insertAdjacentHTML("afterend",new_title_form);
                document.getElementById('edit_menu_holder').parentElement.remove();
                editorLog("change-title in progress")
                document.getElementById('actively_editing').focus();
            } else if (dataAction == "change-caption") {
                alert("editing captions not implemented yet");
                return ;
                var this_caption = document.getElementById('edit_menu_holder').parentElement;
                var this_env_id = this_caption.getAttribute("data-source_id");
                var new_title_form = standard_caption_form(this_env_id);
                document.getElementById('edit_menu_holder').parentElement.insertAdjacentHTML("afterend",new_title_form);
                document.getElementById('edit_menu_holder').parentElement.remove();
                editorLog("change-caption in progress")
                document.getElementById('actively_editing').focus();
            } else {
                editorLog("unknown dataAction", dataAction);
                alert("I don;t know what to do llllllll dataAction " + dataAction)
            }
        }  // dataAction
          else if (dataEnv) {  // this has to come after dataAction, because if both occur,
                               // dataAction says to do something, and dataEnv says what to do
              e.preventDefault();  // was this handled earlier?
              editorLog("in dataEnv", dataEnv);
              editorLog("selected a menu item with no action and no location");
              $("#choose_topic").parent().addClass("past");
              editorLog("apparently selected", theChooseCurrent);
              theChooseCurrent.removeAttribute("id");
              theChooseCurrent.setAttribute('class', 'chosen');

        //      if (dataEnv in inner_menu_for()) {  // object names a collection, so make submenu
              if (dataEnv in submenu_options) {  // object names a collection, so make submenu
                  editorLog("making a menu for", dataEnv);
                  var edit_submenu = document.createElement('ol');
                  edit_submenu.innerHTML = menu_options_for("", dataEnv, "inner");
                  theChooseCurrent.insertAdjacentElement("beforeend", edit_submenu);
                  document.getElementById('choose_topic').focus();

                           // determine whether both of these next cases can occur
              } else if (dataEnv in objectStructure || dataEnvParent in objectStructure) {
              // we just selected an action, so do it
                      // that probably involves adding something before or after a given object
                  editorLog("making a new", dataEnv, "within", dataEnvParent);

                  var before_after = $("#edit_menu_holder > #edit_menu > .chosen").attr("data-location");

                  if (dataEnv == "source") {
                      alert(" making source");
                      show_source(object_of_interest, before_after);
                      edit_menu_from_current_editing("entering");
                      return
         //          } else if (dataEnv == "save") {
         //             save_source();
         //             edit_menu_from_current_editing("entering");
                   }
                  editorLog("create object to edit",dataEnv, object_of_interest, before_after);
                  var new_obj = create_object_to_edit(dataEnv, object_of_interest, before_after);
                  if (!new_obj) { edit_menu_from_current_editing("entering"); return "" }
                  editorLog("new_obj", new_obj);
                  edit_in_place(new_obj, "new");
                  var new_obj_id = new_obj.id;
                  editorLog("are we editing id", new_obj_id);
                  editorLog("are we editing", new_obj);
                  editorLog("  JJJ  current_editing", current_editing["level"], current_editing["location"].length, current_editing["tree"].length, current_editing["tree"][current_editing["level"]]);
                  editorLog("    current_editing", current_editing);
                  object_of_interest.classList.remove("may_select");
                  object_of_interest.classList.remove("may_enter");
                  if (tmp = document.getElementById('edit_menu_holder')) { tmp.remove() }
                  if (dataEnv.startsWith("sbs")) {
                      editorLog("added sbs, now add to it", new_obj_id);
                      editorLog("document.getElementById(new_obj_id)", document.getElementById(new_obj_id));
                      var first_panel_id = document.getElementById(new_obj_id).firstElementChild.firstElementChild.id;
                      editorLog("first_panel_id", first_panel_id, document.getElementById(first_panel_id));
                      make_current_editing_tree_from_id(first_panel_id);
                      edit_menu_from_current_editing("entering");
                  }
              } else {
                  editorLog("Error: unknown dataEnv", dataEnv);
                  editorLog("Or maybe unknown dataEnvParent", dataEnvParent);
                  editorLog("moving up the menu -- not");
                  alert("Sorry, not implemented yet!");
                  theChooseCurrent.classList.remove("chosen");
                  theChooseCurrent.parentElement.classList.remove("past");
                  theChooseCurrent.setAttribute("id", "choose_topic");
              }
          }
    } //  // dataEnv
      else {
        editorLog("key that is not meaningful when navigating a menu:", e.code)
    }
    }
}  // main menu navigator

editorLog("adding tab listener");

document.addEventListener('keydown', logKeyDown);

function logKeyDown(e) {
    if (e.code == "ShiftLeft" || e.code == "ShiftRight" || e.code == "Shift") { return }
    prev_prev_char = prev_char;
    prev_char = this_char;
    this_char = e;
    editorLog("logKey",e,"XXX",e.code);
    editorLog("are we editing", document.getElementById('actively_editing'));
    editorLog("is there already an edit menu?", document.getElementById('edit_menu_holder'));

    var input_region = document.activeElement;
    editorLog("input_region", input_region);
    // if we are writing something, keystrokes usually are just text input
    if (document.getElementById('actively_editing')) {
        editorLog("                 we are actively editing");

        if (e.code == "Tab" && !document.getElementById('local_menu_holder')) {
   // disabled for now
            e.preventDefault();
            return ""
            create_local_menu()
        } else if (document.getElementById('local_menu_holder')) {
            main_menu_navigator(e);
        } else {
            local_editing_action(e)
        }

    } else if (document.getElementById('phantomobject')) {
        var the_phantomobject = document.getElementById('phantomobject');

        if (the_phantomobject.classList.contains('move')) {
            move_object(e)
        } else {
            alert("do not know what to do with that")
        }
    } else {
        console.log("calling main_menu_navigator");
        main_menu_navigator(e);
    }
}

document.addEventListener('focus', function() {
//  editorLog('focused:', document.activeElement)
//  editorLog('which has content XX' + document.activeElement.innerHTML + "VV")
  prev_prev_focused_element = prev_focused_element;
  prev_focused_element = this_focused_element;
  this_focused_element = document.activeElement;
  $('.in_edit_tree').removeClass('in_edit_tree');
//  $(':focus').parent().addClass('in_edit_tree');
  $('#edit_menu_holder:first-child').parent().addClass('in_edit_tree');
  $('#edit_menu_holder').prev().addClass('in_edit_tree');
/*
  var edit_tree = $(':focus').parents();
  // put little lines on teh right, to show the local heirarchy
  for (var i=0; i < edit_tree.length; ++i) {
      if (edit_tree[i].getAttribute('id') == "content") { break }
      edit_tree[i].classList.add('in_edit_tree')
  }
*/
}, true);

// make the top level menu
/* make a function which is called after the source is imported 

e_tree = current_editing["tree"];
editorLog("e_tree", e_tree);
e_level = current_editing["level"];
editorLog("e_level", e_level);
e_location = current_editing["location"];
editorLog("e_location", e_location);
console.log("               making the initial menu for", e_tree[e_level][e_location]);
edit_menu_for(e_tree[e_level][e_location], "entering")
*/

function xml_id_of(xml) {
    var this_id = "";
    if (xml.attributes.length > 0) {
// bad code because I dopied and was too lazy to rewrite
        parseLog(xml.nodeName, "has attributes", xml.attributes);
        for (var j = 0; j < xml.attributes.length; j++) {
            var attribute = xml.attributes.item(j);
            if (attribute.nodeName == "permid") { this_id = attribute.nodeValue }
      // these look backward, but that seems to be how PTX does it currently
            if (!this_id && attribute.nodeName == "xml:id") { this_id = attribute.nodeValue }
        }
    }
    if (!this_id) {
        this_id = randomstring()
    }
    return this_id
}

