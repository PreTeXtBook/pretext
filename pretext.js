/*******************************************************************************
 * pretext.js
 *******************************************************************************
 * The main front-end controller for PreTeXt documents.
 *
 * Homepage: pretextbook.org
 * Repository: https://github.com/PreTeXtBook/JS_core
 *
 * Authors: Michael DuBois, David Farmer, Rob Beezer
 *
 *******************************************************************************
 */

function toggletoc() {
   thesidebar = document.getElementById("ptx-sidebar");
   thesidebar.classList.toggle("hideme");
}

window.addEventListener("load",function(event) {
       thetocbutton = document.getElementsByClassName("toc-toggle")[0];
       thetocbutton.addEventListener('click', () => toggletoc() );
});

