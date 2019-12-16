
var icon = {
  "warning": "⚠️ ",
  "commentary": "&#9749;",
  "media": "&#9654;",
  "tip": "&#128227;",
  "worksheet": "&#128196;",
  "assesment": "A<sup>+</sup>",
  "slides": "&#128251;",
  "outcomes": "&#10003;"
};

var html_words_of = {
  "warning": "Common pitfall",
  "commentary": "Alert",
  "media": "An amusing demo",
  "tip": "Tip: discussion point",
  "worksheet": "Worksheet:",
  "assesment": "Sample exam:",
  "slides": "Slides:",
  "outcomes": "Learning outcomes"
}

// <br>&nbsp;&nbsp;&nbsp;<a href='word'>Word</a> <a href='word'>PTX</a> <a href='word'>PDF</a></span>",

var type_name = {
  "warning": "warning",
  "commentary": "commentary",
  "media": "media",
  "tip": "tip",
  "worksheet": "worksheet",
  "assesment": "assesment",
  "slides": "slides",
  "outcomes": "outcomes"
};

console.log("in instructor.js", role, "role", logged_in, "logged_in");

if (role=="instructor") {
  console.log("                       loading instructor resources");

  var instructor_resources = document.querySelectorAll(".instructor");

  console.log('instructor_resources.length', instructor_resources.length);

  var icons_on_this_page = [];

  for (var j=0; j < instructor_resources.length; ++j) {
    var instructor_resource = instructor_resources[j];
    var instructor_resource_parent_id = instructor_resource.parentNode.id;
    console.log("     XXXXXXXXXXXX    instructor_resource.parentNode", instructor_resource.parentNode);
    console.log("instructor_resource_parent_id", instructor_resource_parent_id);
    if(instructor_resource_parent_id) {
    }  else {
        instructor_resource_parent_id = instructor_resource.parentNode.parentNode.id;
    }

    this_type = instructor_resource.getAttribute("data-resource");
    this_icon = icon[this_type];
    var id_of_this_icon = "resourceid" + j;
    icons_on_this_page.push([type_name[this_type], this_icon, id_of_this_icon]);

    console.log("this_type", this_type, "this_icon", this_icon, "html_words_of[this_type]", html_words_of[this_type]);
    this_item_with_resource =  document.getElementById(instructor_resource_parent_id);
    console.log("instructor_resource_parent_id", instructor_resource_parent_id, "this_item_with_resource", this_item_with_resource);

    var this_margin_resource = document.createElement('div');
    this_margin_resource.setAttribute('class', 'marginresource');
    this_margin_resource.setAttribute('id', id_of_this_icon);
    this_margin_resource.innerHTML = "<span class='icon " + this_type + "'>" + this_icon + "</span>";
    if(!(this_title = instructor_resource.getAttribute("title"))) {
        this_title = html_words_of[this_type]
    }
    if(instructor_resource.hasAttribute("data-content")) {
        this_content = instructor_resource.getAttribute("data-content");
        this_title = '<a href="" data-knowl="' + this_content + '">' + this_title + '</a>';
    }
    var links_html = ""
    if(instructor_resource.hasAttribute("data-links")) {
        var this_links = instructor_resource.getAttribute("data-links");
        these_links = this_links.split(";");
        links_html = '<span class="resource_links">'
        console.log("      OOOOOOOOOOOOOO these_links", these_links, "these_links.length", these_links.length);
        if(these_links.length > 0) {
             console.log("these_links[0]", these_links[0]);
            }
        tmpJ = these_links.length;
        console.log("tmpJ", tmpJ);
        for(var jj=0; jj < these_links.length; ++jj) {
            console.log( "      UUUUUUUUUUUUUu    these_links[jj]", these_links[jj]);
            this_type_and_link = these_links[jj].split(",");
            if(jj>0) { links_html += ", " }
            links_html  += '<a href="' + this_type_and_link[1] + '">' + this_type_and_link[0] + '</a>';
            }
        links_html += 'XX</span>';
        console.log("done adding links to title");
        }
    this_title = '<span class="resource_description">' + this_title
    if(links_html) {
        this_title += links_html
        }
    this_title += '</span>';
    this_margin_resource.innerHTML += this_title;
//    this_item_with_resource.insertBefore(this_margin_resource);
    this_item_with_resource.insertBefore(this_margin_resource, this_item_with_resource.firstChild);
    console.log("appended to ",this_item_with_resource);
  }

  icons_on_this_page.sort();

  var icon_legend_for_this_page = document.createElement('div');
  var prev_icon = "";
  var icon_list = '<span class="icongroup">' + "<span class='icon_name'>" + icons_on_this_page[0][0] + ":</span> ";
  for (var j=0; j < icons_on_this_page.length; ++j) {
    next_icon = icons_on_this_page[j][1];
    if(j > 0 && next_icon !== prev_icon) {
        icon_list += '</span>' + "<br>";
        icon_list += '<span class="icongroup">' + "<span class='icon_name'>" + icons_on_this_page[j][0] + ":</span> ";
        icon_list += '<a href="#' + icons_on_this_page[j][2] + '">' + next_icon + '</a>';
    } else {
        icon_list += '<a href="#' + icons_on_this_page[j][2] + '">' + next_icon + '</a>';
    }
    prev_icon = next_icon;
  }
  icon_list += '</span>';

  icon_legend_for_this_page.setAttribute('class', 'iconlegend');
  icon_legend_for_this_page.innerHTML = icon_list
  document.body.appendChild(icon_legend_for_this_page);

}  // if logged in as instructor
