/*******************************************************************************
 * pretext.js
 *******************************************************************************
 * The main front-end controller for PreTeXt documents.
 *
 * Homepage: pretextbook.org
 * Repository: https://github.com/PreTeXtBook/JS_core
 *
 * Authors: David Farmer, Rob Beezer
 *
 *******************************************************************************
 */

function toggletoc() {
   thesidebar = document.getElementById("ptx-sidebar");
   if (thesidebar.classList.contains("hidden") || thesidebar.classList.contains("visible")) {
       thesidebar.classList.toggle("hidden");
       thesidebar.classList.toggle("visible");
   } else if (thesidebar.offsetParent === null) {  /* not currently visible */
       thesidebar.classList.toggle("visible");
   } else {
       thesidebar.classList.toggle("hidden");
   }
/*
   themain = document.getElementsByClassName("ptx-main")[0];
   themain.classList.toggle("notoc");
   console.log("toggled the toc");
*/
}

window.addEventListener("load",function(event) {
       thetocbutton = document.getElementsByClassName("toc-toggle")[0];
       thetocbutton.addEventListener('click', () => toggletoc() );
/*
       thepage = document.getElementsByClassName("ptx-page")[0];
       console.log("thepage", thepage);
       console.log("width", thepage.offsetWidth);
       if (thepage.offsetWidth < 800) {
           toggletoc()
       }
*/
});

window.addEventListener("load",function(event) {
       pagefilename  = window.location.href;
       pagefilename  = pagefilename.match(/[^\/]*$/)[0];
       possibletocentries = document.querySelectorAll('#ptx-toc a[href="' + pagefilename + '"]');
       if (possibletocentries.length == 0) {
           console.log("linked below a subsection");
           pagefilename  = pagefilename.match(/^[^\#]*/)[0];
           possibletocentries = document.querySelectorAll('#ptx-toc a[href="' + pagefilename + '"]');
       }
       if (possibletocentries.length == 0) {
           console.log("error, cannot find", pagefilename, "in TOC");
           return
       }
       possibletocentries[0].scrollIntoView({block: "center"});
       possibletocentries[0].classList.add("active");
});

/* jump to next page if reader tries to scroll past the bottom */
// var hitbottom = false;
// window.onscroll = function(ev) {
//   if ((window.innerHeight + window.scrollY) >= document.body.scrollHeight) {
//     // you're at the bottom of the page
//     console.log("Bottom of page");
//     if (hitbottom) {
//         console.log("hit bottom again");
//         thenextbutton = document.getElementsByClassName("next-button")[0];
//         thenextbutton.click();
//     } else {
//         hitbottom = true;
//         /* only jump to next page if hard scroll in quick succession */
//         window.scrollBy(0, -20);
//         setTimeout(function (){ hitbottom = false }, 1000);
//     }
//   }
// };

