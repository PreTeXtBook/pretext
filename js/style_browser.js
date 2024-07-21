window.onload = function() {
  // get link elements
  var linkElements = document.getElementsByTagName("link");
  // get links with style_, colors_ and shell_ css:
  for (var i = 0; i < linkElements.length; i++) {
    if (linkElements[i].href.includes("style_")) {
      var styleLink = linkElements[i];
    }
    if (linkElements[i].href.includes("colors_")) {
      var colorsLink = linkElements[i];
    }
    if (linkElements[i].href.includes("banner_")) {
      var bannerLink = linkElements[i];
    }
    if (linkElements[i].href.includes("shell_")) {
      var shellLink = linkElements[i];
    }
    if (linkElements[i].href.includes("toc_")) {
      var tocLink = linkElements[i];
    }
    if (linkElements[i].href.includes("navbar_")) {
      var navbarLink = linkElements[i];
    }
  }
  

  // Create a new div element
  var styleSelectorDiv = document.createElement("div"); 

  styleSelectorDiv.setAttribute("id", "styleSelectorDiv");
  styleSelectorDiv.setAttribute("style", "position: sticky; z-index:200; top:auto; bottom: 0; width: 100%; background-color: #efefef; padding: 10px; font-size: small; border-top: 1px solid #ccc;");

  // Add some content to the new div
  styleSelectorDiv.innerHTML = `
    Colors: <select id="colorSelector">
      <option value="default">default</option>
      <option value="blue_green">blue_green</option>
      <option value="blue_grey">blue_grey</option>
      <option value="blue_red_dark">blue_red_dark</option>
      <option value="blue_red">blue_red</option>
      <option value="bluegreen_grey">bluegreen_grey</option>
      <option value="brown_gold">brown_gold</option>
      <option value="darkmartiansands">darkmartiansands</option>
      <option value="focused_gray_aqua">focused_gray_aqua</option>
      <option value="focused_light">focused_light</option>
      <option value="green_blue">green_blue</option>
      <option value="green_plum">green_plum</option>
      <option value="maroon_grey">maroon_grey</option>
      <option value="mariansands">mariansands</option>
      <option value="orange_navy">orange_navy</option>
      <option value="pastel_blue_orange">pastel_blue_orange</option>
      <option value="red_blue">red_blue</option>
      <option value="ruby_amethyst">ruby_amethyst</option>
      <option value="ruby_emerald">ruby_emerald</option>
      <option value="ruby_turquoise">ruby_turquoise</option>
      </select>
      &nbsp;&nbsp;&nbsp;
    Inner style: <select id="innerStyleSelector">
      <option value="default">default</option>
      <option value="oscarlevin">oscarlevin</option>
      <option value="soundwriting">soundwriting</option>
    </select>
    &nbsp;&nbsp;&nbsp;
    Outer style: <select id="outerStyleSelector">
      <option value="default">default</option>
      <option value="crc">crc</option>
      <option value="wide">wide</option>
    </select>
  `;

  // Append the new div to the end of the body
  document.body.appendChild(styleSelectorDiv);

  // add margin to the bottom of the body element:
  document.body.style.marginBottom = "4em";

  function updateStyles() {
    var colorSelector = document.getElementById("colorSelector");
    var innerStyleSelector = document.getElementById("innerStyleSelector");
    var outerStyleSelector = document.getElementById("outerStyleSelector");

    var currentStyles = localStorage.getItem("pretext_styles") || "default,default,default";

    function activateStyle() {
      colorsLink.href = "_static/pretext/css/colors_" + colorSelector.value + ".css";
      styleLink.href = "_static/pretext/css/style_" + innerStyleSelector.value + ".css";
      bannerLink.href = "_static/pretext/css/banner_" + outerStyleSelector.value + ".css";
      shellLink.href = "_static/pretext/css/shell_" + outerStyleSelector.value + ".css";
      tocLink.href = "_static/pretext/css/toc_" + outerStyleSelector.value + ".css";
      navbarLink.href = "_static/pretext/css/navbar_" + outerStyleSelector.value + ".css";

      localStorage.setItem("pretext_styles", colorSelector.value + "," + innerStyleSelector.value + "," + outerStyleSelector.value);
    }

    colorSelector.onchange = () => {
      activateStyle();
    }
    innerStyleSelector.onchange = () => {
      activateStyle();
    }
    outerStyleSelector.onchange = () => {
      activateStyle();
    }

    colorSelector.value = currentStyles.split(",")[0];
    innerStyleSelector.value = currentStyles.split(",")[1];
    outerStyleSelector.value = currentStyles.split(",")[2];
    activateStyle(colorSelector, currentStyles.split(",")[0]);
    activateStyle(innerStyleSelector, currentStyles.split(",")[1]);
    activateStyle(outerStyleSelector, currentStyles.split(",")[2]);
  }

  updateStyles();
}