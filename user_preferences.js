
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

var font_families = {
    'RS': "'Roboto Serif', serif;",
    'OS': "'Open Sans', sans-serif;"
}

var font_vals = {
 //   'face': 'serif',
    'size': [12, 8, 20],
    'height': [135, 80, 200],
    'wspace': [0, -10,20],
    'lspace': [0, -20,20],
    'wdth': [100, 50, 150],
    'wght': [400, 100, 1000]
}

function fontcss(fvals) {
console.log("in fontcss",fvals);
  var csskeys = Object.keys(fvals);
  var this_style = "";
  for (var j=0; j < csskeys.length; ++j) {
    this_key = csskeys[j];
    document.getElementById("the" + this_key).innerHTML = fvals[this_key][0];

console.log("in fontcss", this_key, "with value", fvals[this_key][0], "/10", fvals[this_key][0]/10.0);
    if (this_key == 'size') {
      this_style += "font-size: " + fvals[this_key][0].toString() + "pt; "
    } else if (this_key == 'height') {
      this_style += "line-height: " + (fvals[this_key][0]/100.0).toString() + "; "
    } else if (this_key == 'lspace') {
      this_style += "letter-spacing: " + (fvals[this_key][0]/200.0).toString() + "rem; "
    } else if (this_key == 'wspace') {
      this_style += "word-spacing: " + (fvals[this_key][0]/50.0).toString() + "rem; "
    }
  }

  this_style += "font-variation-settings: ";
  for (var j=0; j < csskeys.length; ++j) {
    this_key = csskeys[j];

    if (this_key == 'wdth') {
      this_style += "'wdth' " + fvals[this_key][0].toString() + ","
    } else if (this_key == 'wght') {
      this_style += "'wght' " + fvals[this_key][0].toString() + ","
    }
  }
  this_style = this_style.slice(0, -1);
  this_style += ";";

console.log("returning this_style", this_style);
  return this_style
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



editorLog("adding tab listener");

document.addEventListener('keydown', logKeyDown);

function nextsibligntabbable(startingplace, where) {
    var candidate = startingplace.nextElementSibling;
    if (where == "previous" ) { candidate = startingplace.previousElementSibling }

    while (candidate) {
console.log("candidate A", candidate);
      if (candidate.hasAttribute("tabindex")) { return candidate }
console.log("candidate B", candidate);
      if (where == "next" ) { candidate = candidate.nextElementSibling }
      else { candidate = candidate.previousElementSibling }
    }
}

function logKeyDown(e) {
    if (e.code == "ShiftLeft" || e.code == "ShiftRight" || e.code == "Shift") { return }
    prev_prev_char = prev_char;
    prev_char = this_char;
    this_char = e;
    console.log("logKey",e,"XXX",e.code);

    var input_region = document.activeElement;
    console.log("input_region", input_region);
    if (input_region.id == "user-preferences-button") {
        if (e.code == "Enter") {
          document.getElementById("preferences_menu_holder").classList.toggle("hidden")
        } else if (e.code == "Tab") {
console.log("tabbing to main pref menu", document.getElementById("preferences_menu_holder").firstElementChild);
console.log("tabbing to main pref menu", document.getElementById("preferences_menu_holder").firstElementChild.firstElementChild);
          e.preventDefault();
          document.getElementById("preferences_menu_holder").firstElementChild.firstElementChild.focus()
        }
    } else if (input_region.hasAttribute("data-env")) {
      var this_submenu = input_region.getElementsByTagName("ol")[0];
console.log("this_submenu C", this_submenu);
      if ((e.code == "Enter") || (e.code == "ArrowRight")) {
console.log("selecting",input_region, "which has", input_region.getElementsByTagName("ol"), "first",input_region.getElementsByTagName("ol")[0]);
        this_submenu.classList.toggle("hidden")
        input_region.classList.toggle("selected")
        input_region.parentElement.classList.toggle("active")
      } else if (e.code == "Tab" && e.shiftKey) {
        e.preventDefault();
        if (input_region.classList.contains("selected")) {
          this_submenu.classList.loggle("hidden");
          input_region.classList.loggle("selected");
        } else { // cycle up through the elements
     //     previous_sibling = input_region.previousElementSibling;
          previous_sibling = nextsibligntabbable(input_region, "previous");
          if (previous_sibling) { previous_sibling.focus() }
          else {
            document.getElementById("preferences_menu_holder").classList.toggle("hidden");
            document.getElementById("user-preferences-button").focus();
          }
        }
      } else if (e.code == "Tab") {
        e.preventDefault();
        if (input_region.classList.contains("selected")) {
          var firstchild = this_submenu.firstElementChild;
          if (firstchild.hasAttribute("tabindex")) {
            firstchild.focus()
          } else {
            nextsibligntabbable(firstchild, "next").focus()
          }
        } else { // cycle through the elements
//          next_sibling = input_region.nextElementSibling;
          next_sibling = nextsibligntabbable(input_region, "next");
          if (next_sibling) { next_sibling.focus() }
          else {
            document.getElementById("preferences_menu_holder").classList.toggle("hidden");
            document.getElementById("user-preferences-button").focus();
          }
        }
      }
    } else if (input_region.hasAttribute("data-val")) {
console.log("input_region", input_region);
console.log("input_regionparentElement", input_region.parentElement);
      if ((e.code == "Enter") || (e.code == "ArrowRight")) {
console.log("font_vals is", font_vals);
        var dataval = input_region.getAttribute("data-val");
        var datachange = input_region.getAttribute("data-change");
console.log("dataval", dataval, "datachange",datachange);
        if (input_region.parentElement.classList.contains("fonts")) {
          font_vals[dataval][0] += parseFloat(datachange);
          if (font_vals[dataval][0] < font_vals[dataval][1]) { font_vals[dataval][0] = font_vals[dataval][1] }
          else if (font_vals[dataval][0] > font_vals[dataval][2]) { font_vals[dataval][0] = font_vals[dataval][2] }
console.log("font_vals are", font_vals);
console.log("css font_vals", fontcss(font_vals));
          var new_style = fontcss(font_vals);
          var paras = document.getElementsByClassName('para');
          for (i = 0; i < paras.length; i++) {
            paras[i].setAttribute('style', new_style);
          }
        } else if (input_region.parentElement.classList.contains("fontfamily")) {
          document.body.setAttribute("data-font", datachange);
          var checks = document.getElementsByClassName('ffcheck');
          for (i = 0; i < checks.length; i++) {
            checks[i].innerHTML = '';
          }
          document.getElementById("the" + datachange).innerHTML = "✔️";
        } else if (input_region.parentElement.classList.contains("avatar")) {
          var checks = document.getElementsByClassName('avatarcheck');
          for (i = 0; i < checks.length; i++) {
            checks[i].innerHTML = '';
          }
          document.getElementById("theavatarbutton").innerHTML = dataval;
          document.getElementById("the" + dataval).innerHTML = "✔️";
        } else if (input_region.parentElement.classList.contains("atmosphere")) {
          document.body.setAttribute("data-atmosphere", dataval);
          var checks = document.getElementsByClassName('atmospherecheck');
          for (i = 0; i < checks.length; i++) {
            checks[i].innerHTML = '';
          }
          document.getElementById("the" + dataval).innerHTML = "✔️";

        }
      } else if (e.code == "Tab" && e.shiftKey) {
        e.preventDefault();
//        previous_sibling = input_region.previousElementSibling;
        previous_sibling = nextsibligntabbable(input_region, "previous");

console.log("previous_sibling",previous_sibling);
        if (previous_sibling) { previous_sibling.focus() }
        else {
          input_region.parentElement.parentElement.parentElement.classList.toggle("active");
          input_region.parentElement.parentElement.classList.toggle("selected");
          input_region.parentElement.parentElement.focus();
          input_region.parentElement.classList.toggle("hidden");
        }
      } else if (e.code == "Tab") {
        e.preventDefault();
  //      next_sibling = input_region.nextElementSibling;
        next_sibling = nextsibligntabbable(input_region, "next");
        if (next_sibling) { next_sibling.focus() }
        else {
          input_region.parentElement.parentElement.parentElement.classList.toggle("active");
          input_region.parentElement.parentElement.classList.toggle("selected");
          input_region.parentElement.parentElement.focus();
          input_region.parentElement.classList.toggle("hidden");
        }
      }
    }


    return;

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

