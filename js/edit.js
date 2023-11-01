
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
chosen_edit_option = readCookie(chosen_edit_option_key) || "";
editing_mode = chosen_edit_option;  /* delete one of those variables */
debugLog("chosen_edit_option", chosen_edit_option, "chosen_edit_option", chosen_edit_option > 0);


objectStructure = {
  "type": {
    "html": {
        "tag": "span",
        "attributes": ['class="type"', 'data-parent_id="<&>xml:id<;>"', 'data-editable="70XX"', 'tabindex="-1"'],
        "pieces": [["(capitalize,sourcetag)", ""]]
    }
  },
  "type-child": {
    "html": {
        "tag": "span",
        "attributes": ['class="type"', 'data-editable="70YY"', 'tabindex="-1"'],
        "pieces": [["(capitalize,sourcetag)", ""]]
   //     "pieces": [["(capitalize,type-contained)", ""]]
    }
  },
  "type-proof": {
    "html": {
        "tag": "span",
        "attributes": ['class="type"', 'data-editable="70YY"', 'tabindex="-1"'],
        "pieces": [["(literal,Proof)", ""]]
   //     "pieces": [["(capitalize,type-contained)", ""]]
    }
  },
  "sectiontype": {
    "html": {
        "tag": "span",
        "attributes": ['class="type"'],  // the type of a section is not editable?
        "pieces": [["(capitalize,sourcetag)", ""]]
    }
  },
  "codenumber": { 
    "html": {
        "tag": "span",
        "attributes": ['class="codenumber"'],
        "pieces": [["(codenumber,)", ""]]  // maybe () was a bad idea?  do we need a triple?
    }
  },
  "period": {
    "html": {
        "tag": "span",
        "attributes": ['class="period"'],
        "pieces": [["(period,)", ""]]
    }
  },
  "comma": {   // used in bibliography
    "html": {
        "tag": "span",
        "attributes": ['class="comma"'],
        "pieces": [["(comma,)", ""]]
    }
  },
  "titleperiod": {
    "html": {
        "tag": "span",
        "attributes": ['class="period"'],
        "pieces": [["(titleperiod,)", ""]]
    }
  },
  "space": {
    "html": {
        "tag": "span",
        "attributes": ['class="space"'],
        "pieces": [["(space,)", ""]]
    }
  },
  "title": {
    "html": {
        "tag": "span",
        "attributes": ['class="title"', 'data-editable="70"', 'tabindex="-1"'],
        "pieces": [["title", ""]]
    }
  },
  "nbsp": {
    "html": {
        "tag": "",
        "pieces": [["(literal,&nbsp;)", ""]],
    },
    "pretext": {
        "tag": "nbsp",
        "pieces": []
    },
    "source": {
        "pieces": []
    }
  },
  "idx": {
    "html": {
        "tag": "",
        "pieces": [],
    },
    "pretext": {
        "tag": "idx",
        "pieces": [["content", ""]]
    },
    "source": {
        "pieces": [["content", ""]]
    }
  },
  "h": {
    "html": {
        "tag": "",
        "pieces": [],
    },  
    "pretext": {
        "tag": "h",
        "pieces": [["content", ""]]
    },
    "source": {
        "pieces": [["content", ""]]
    }
  },

  "theorem_like_heading": {
    "html": {
        "tag": "h4",
        "cssclass": "heading",
        "attributes": ['class="<&>{cssclass}<;>"', 'data-parent_id="<&>xml:id<;>"'],
        "pieces": [["{type}", ""], ["{space}", ""], ["{codenumber}", ""], ["{period}", ""],  ["{space}", ""], ["{title}", ""], ["{titleperiod}", ""]]
          // * means editable piece
    }
  },
  "proof_like_heading": {
    "html": {
        "tag": "h5",
        "cssclass": "heading",
        "attributes": ['class="<&>{cssclass}<;>"', 'xml:id="<&>xml:id<;>"'],
        "pieces": [["{type-child}", ""], ["{period}", ""]]
    }
  },
  "proof_heading": {
    "html": {
        "tag": "h5",
        "cssclass": "heading",
        "attributes": ['class="<&>{cssclass}<;>"', 'xml:id="<&>xml:id<;>"'],
        "pieces": [["{type-proof}", ""], ["{period}", ""]]
    }
  },
  "section_like_heading": {
    "html": {
        "tag": "h2",
        "cssclass": "heading hide-type",
        "attributes": ['class="<&>{cssclass}<;>"', 'data-parent_id="<&>xml:id<;>"'],
        "pieces": [["{sectiontype}", ""], ["{codenumber}", ""], ["{space}", ""], ["{title}", ""]]
    }
  },
  "title_heading": {
    "html": {
        "tag": "h2",
        "cssclass": "heading",
        "attributes": ['class="<&>{cssclass}<;>"', 'data-parent_id="<&>xml:id<;>"'],
        "pieces": [["{title}", ""], ["{period}", ""]]
    }
  },
  "task_like_heading": {
    "html": {
        "tag": "h6",
        "cssclass": "heading",
        "attributes": ['class="<&>{cssclass}<;>"', 'data-parent_id="<&>xml:id<;>"'],
        "pieces": [["{codenumber}", ""], ["{space}", ""], ["{title}", ""]]
    }
  },
  "caption_like_heading": {
    "html": {
        "tag": "h5",
        "cssclass": "captionheading",
        "attributes": ['class="<&>{cssclass}<;>"', 'data-parent_id="<&>xml:id<;>"'],
        "pieces": [["{type}", ""], ["{space}", ""], ["{codenumber}", ""], ["{period}", ""], ["{space}", ""]]
    }
  },
  "xref": {
    "html": {
        "tag": "span",
        "attributes": ['class="ref tmp"', 'id="<&>xml:id<;>"', 'ref="<&>ref<;>"'],
        "pieces": [["(literal,REFERENCE)", ""]],
    },
    "pretext": {
        "tag": "xref",
        "attributes": ['ref="<&>ref<;>"', 'text="<&>text<;>"'],
        "pieces": [["content", ""]]
    },
    "source": {
        "pieces": [["content", ""]],
        "attributes": [["ref", "*"], ["text", ""],["detail",""],["first",""],["last",""]]
    }
  },
  "introduction": {
    "html": {
        "tag": "section",
        "attributes": ['class="introduction"', 'id="<&>xml:id<;>"', 'data-editable="XYX"', 'tabindex="-1"'],
        "pieces": [["content", ""]],
    },
    "pretext": {
        "tag": "introduction",
        "attributes": ['xml:id="<&>xml:id<;>"'],
        "pieces": [["title", "title"], ["content", ""]]
    },
    "source": {
        "pieces": [["title", "*"], ["content", "p"]]
    }
  },
  "conclusion": {
    "html": {
        "tag": "section",
        "attributes": ['class="conclusion"', 'id="<&>xml:id<;>"', 'data-editable="XYX"', 'tabindex="-1"'],
        "pieces": [["{proof_like_heading}", ""], ["content", ""]],
    },
    "pretext": {
        "tag": "conclusion",
        "attributes": ['xml:id="<&>xml:id<;>"'],
        "pieces": [["title", "title"], ["content", ""]]
    },
    "source": {
        "pieces": [["title", "*"], ["content", "p"]]
    }
  },

  "worksheet": {
    "html": {
        "tag": "section",
        "attributes": ['class="worksheet"', 'id="<&>xml:id<;>"', 'data-editable="XYX"', 'tabindex="-1"'],
        "pieces": [["{section_like_heading}", ""], ["content", ""]],
    },
    "pretext": {
        "tag": "worksheet",
        "attributes": ['xml:id="<&>xml:id<;>"'],
        "pieces": [["title", "title"], ["content", ""]]
    },
    "source": {
        "pieces": [["title", "*"], ["content", "p"]]
    }
  },
  "section": {
    "html": {
        "tag": "section",
        "attributes": ['class="section"', 'id="<&>xml:id<;>"', 'data-editable="XYX"', 'tabindex="-1"'],
        "pieces": [["{section_like_heading}", ""], ["content", ""]],
    },
    "pretext": {
        "tag": "section",
        "attributes": ['xml:id="<&>xml:id<;>"'],
        "pieces": [["title", "title"], ["content", ""]]
    },
    "source": {
        "pieces": [["title", "*"], ["content", "p"]]
    }
  },
  "subsection": {
    "html": {
        "tag": "section",
        "attributes": ['class="subsection"', 'id="<&>xml:id<;>"', 'data-editable="XYX"', 'tabindex="-1"'],
        "pieces": [["{section_like_heading}", ""], ["content", ""]],
    },
    "pretext": {
        "tag": "subsection",
        "attributes": ['xml:id="<&>xml:id<;>"'],
        "pieces": [["title", "title"], ["content", ""]]
    },
    "source": {
        "pieces": [["title", "*"], ["content", "p"]]
    }
  },
  "paragraphs": {
    "html": {
        "tag": "section",
        "attributes": ['class="paragraphs"', 'id="<&>xml:id<;>"', 'data-editable="XYX"', 'tabindex="-1"'],
        "pieces": [["{title_heading}", ""], ["content", ""]],
    },
    "pretext": {
        "tag": "paragraphs",
        "attributes": ['xml:id="<&>xml:id<;>"'],
        "pieces": [["title", "title"], ["content", ""]]
    },
    "source": {
        "pieces": [["title", "*"], ["content", "p"]]
    }
  },
  "exercises": {
    "html": {
        "tag": "section",
        "attributes": ['class="exercises"', 'id="<&>xml:id<;>"', 'data-editable="XYX"', 'tabindex="-1"'],
        "pieces": [["{section_like_heading}", ""], ["content", ""]],
    },
    "pretext": {
        "tag": "exercises",
        "attributes": ['xml:id="<&>xml:id<;>"'],
        "pieces": [["title", "title"], ["content", ""]]
    },
    "source": {
        "pieces": [["title", "*"], ["content", "p"]]
    }
  },
  "exercisegroup": {
    "html": {
        "tag": "section",
        "attributes": ['class="exercisegroup"', 'id="<&>xml:id<;>"', 'data-editable="XYX"', 'tabindex="-1"'],
        "pieces": [["{section_like_heading}", ""], ["content", ""]],
    },
    "pretext": {
        "tag": "exercisegroup",
        "attributes": ['xml:id="<&>xml:id<;>"'],
        "pieces": [["title", "title"], ["content", ""]]
    },
    "source": {
        "pieces": [["title", "*"], ["content", "p"]]
    }
  },


  "page": {
    "html": {
        "tag": "section",
        "attributes": ['class="onepage"', 'id="<&>xml:id<;>"', 'data-editable="PPP"', 'tabindex="-1"'],
        "pieces": [["content", ""]],
    },
    "pretext": {
        "tag": "page",
        "attributes": ['xml:id="<&>xml:id<;>"'],
        "pieces": [["content", ""]]
    },
    "source": {
        "pieces": [["content", "p"]]
    }
  },
  "objectives": {
    "html": {
        "tag": "article",
        "cssclass": "objectives",
        "pieces": [["{proof_like_heading}", ""], ["content",""]],
        "attributes": ['id="<&>xml:id<;>"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"', 'class="<&>{cssclass}<;>"'],
        "data_editable": "160"
    },
    "pretext": {
        "tag": "objectives",
        "attributes": ['xml:id="<&>xml:id<;>"'],
        "pieces": [["content", ""]]
    },
    "source": {
        "pieces": [["content", "p"]]
    }
  },



  "p": {
    "html": {
        "tag": "p",
        "pieces": [["content", ""]],
        "attributes": ['id="<&>xml:id<;>"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"'],
        "data_editable": "99"
    },
    "pretext": {
        "tag": "p",
        "attributes": ['xml:id="<&>xml:id<;>"'],
        "pieces": [["content", ""]]
    },
    "source": {
        "pieces": [["content", ""]]
    }
  },
/* probably there is a better way to do it, but we have separate elements for p
   that occur in
   text  // ip
   math
   text  // mp
   math
   text  // mp
   math
   text  // fp 
*/
   "ip": {
    "html": {
        "tag": "p",
        "pieces": [["content", ""]],
        "attributes": ['id="<&>xml:id<;>"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"'],
        "data_editable": "99"
    },
    "pretext": {
        "tag_opening": "\n<p",   // note the slimy way of including attributes
        "tag_closing": "",
        "attributes": ['xml:id="<&>xml:id<;>">\n'],
        "pieces": [["content", ""]]
    },
    "source": {
        "pieces": [["content", ""]]
    }
  },
   "mp": {
    "html": {
        "tag": "p",
        "pieces": [["content", ""]],
        "attributes": ['id="<&>xml:id<;>"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"', 'class="mp"'],
        "data_editable": "99"
    },
    "pretext": {
        "tag_opening": "",
        "tag_closing": "",
        "attributes": [],
        "pieces": [["content", ""]]
    },
    "source": {
        "pieces": [["content", ""]]
    }
  },
   "fp": {
    "html": {
        "tag": "p",
        "pieces": [["content", ""]],
        "attributes": ['id="<&>xml:id<;>"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"', 'class="fp"'],
        "data_editable": "99"
    },
    "pretext": {
        "tag_opening": "",
        "tag_closing": "\n</p>\n",
        "attributes": [],
        "pieces": [["content", ""]]
    },
    "source": {
        "pieces": [["content", ""]]
    }
  },

  "li": {
    "html": {
        "tag": "li",
        "pieces": [["content", ""]],
        "attributes": ['id="<&>xml:id<;>"'],
        "data_editable": "98aZ"
    },
    "pretext": {
        "tag": "li",
        "pieces": [["title", "title"], ["content", ""]]
    },
    "source": {
        "pieces": [["title", ""], ["content", "p"]]
    }
  },

  "blockquote": {
    "html": {
        "tag": "blockquote",
        "pieces": [["content", ""], ["attribution", ""]],
        "attributes": ['id="<&>xml:id<;>"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"', 'class="<&>{cssclass}<;>"'],
        "cssclass": "blockquote",
        "data_editable": "44?"
    },
    "pretext": {
        "tag": "blockquote",
        "pieces": [["content", ""], ["attribution", "attribution"]],
    },
    "source": {
        "pieces": [["content", "p"], ["attribution", ""]]  // attribution can contain a "line".  come back to that
    }
  },

  "list": {
    "html": {
        "tag": "ol",
        "pieces": [["content", ""]],
        "attributes": ['id="<&>xml:id<;>"', 'list-style-type="a"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"'],
        "data_editable": "AAA"
    },
    "pretext": {
        "tag": "ol",
        "pieces": [["content", ""]],
        "attributes": ['label="A"']
    },
    "source": {
        "pieces": [["title", ""], ["content", "li"]],
        "attributes": [["label", "A"]]
    }
  },

  "figure": {
    "html": {
        "tag": "figure",
        "pieces": [["content",""],["{caption}", ""]],
        "attributes": ['id="<&>xml:id<;>"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"', 'class="<&>{cssclass}<;>"'],
        "data_editable": "32",
        "cssclass": "figure figure-like"
    },
    "pretext": {
        "tag": "figure",
        "pieces": [["content"], ["{caption}"]],
        "attributes": ['xml:id="<&>xml:id<;>"']
    },
    "source": {
        "pieces": [["content", ""], ["captiontext", ""]],
        "attributes": []
    }
  },

  "image": {
    "html": {
        "tag": "div",
        "pieces": [["{bareimage}",""]],
        "attributes": ['id="<&>xml:id<;>"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"', 'class="<&>{cssclass}<;>"', 'style="width: <&>width<;>%; margin-right: <&>marginright<;>%; margin-left: <&>marginleft<;>%"'],
        "data_editable": "31",
        "cssclass": "image-box"
    },
    "pretext": {
        "tag": "image",
        "pieces": [],
        "attributes": ['xml:id="<&>xml:id<;>"', 'source="<&>source<;>"', 'alt="<&>alt<;>"', 'width="<&>width<;>%"', 'margins="<&>marginleft<;>% <&>marginright<;>%"']
    },
    "source": {
        "pieces": [["",""]],
        "attributes": [["source", ""], ["width", "40"], ["marginleft", "20"], ["marginright", "40"], ["alt", ""]]
    }
  },

  "bareimage": {
    "html": {
        "tag": "img",
        "pieces": [],
        "attributes": ['src="<&>source<;>"', 'alt="<&>alt<;>"', 'class="contained"'],
    }
  },

  "sidebyside": {
    "html": {
        "tag": "div",
        "pieces": [["{sbsrow}",""]],
        "attributes": ['id="<&>xml:id<;>"', 'class="<&>{cssclass}<;>"'],
        "cssclass": "sidebyside"
    },
    "pretext": {
        "tag": "sidebyside",
        "pieces": [["content", ""]],
        "attributes": ['xml:id="<&>xml:id<;>"', 'margins="<&>marginleft<;>% <&>marginright<;>%"', 'width="<&>(percentlist,widths)<;>"'],
    },
    "source": {
        "pieces": [["content",""]],
        "attributes": [["marginleft", ""], ["marginright", ""], ["widths", ""]]
    }
  },
  "sbsrow": {
    "html": {
        "tag": "div",
        "pieces": [["content",""]],   // ????
        "attributes": ['class="<&>{cssclass}<;>"', 'style="margin-right: <&>marginright<;>%; margin-left: <&>marginleft<;>%"'],
        "data_editable": "89",
        "cssclass": "sbsrow"
    },
    "pretext": {
        "tag": "",
        "pieces": [["content",""]],
        "attributes": []
    },
    "source": {
        "pieces": [["content",""]],
        "attributes": [["marginleft", "20"], ["marginright", "40"]]
    }
  },
  "sbspanel": {
    "html": {
        "tag": "div",
        "pieces": [["content",""]],
        "attributes": ['id="<&>xml:id<;>"', 'class="<&>{cssclass}<;>"', 'style="width:<&>(nthitem,widths)<;>%"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"'],
        "data_editable": "90",
        "cssclass": "sbspanel"
    },
    "pretext": {
        "tag": "stack",
        "pieces": [["content", ""]],
        "attributes": ['xml:id="<&>xml:id<;>"']
    },
    "source": {
        "pieces": [["content",""]]
    }
  },

  "proof": {
    "html": {
        "tag": "article",
        "cssclass": "proof",
        "pieces": [["{proof_heading}", ""], ["proof",""]],
        "attributes": ['id="<&>xml:id<;>"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"', 'class="<&>{cssclass}<;>"'],
        "data_editable": "60"
    },
    "pretext": {
        "tag": "proof",
        "attributes": ['xml:id="<&>xml:id<;>"'],
        "pieces": [["proof", ""]]
    },
    "source": {
        "pieces": [["content", "p"]]
    }
  },
  "proof-standalone": {
    "html": {
        "tag": "article",
        "cssclass": "proof",
        "pieces": [["{XXXXXnorbeingusedXXXXXXX_proof_heading}", ""], ["content",""]],
        "attributes": ['id="<&>xml:id<;>"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"', 'class="<&>{cssclass}<;>"'],
        "data_editable": "60"
    },
    "pretext": {
        "tag": "proof",
        "attributes": ['xml:id="<&>xml:id<;>"'],
        "pieces": [["content", ""]]
    },
    "source": {
        "pieces": [["content", "p"]]
    }
  },

  "caption": {
    "html": {
        "tag": "figcaption",
        "data_editable": "321",
    //    "attributes": ['id="<&>xml:id<;>"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"'],
        "attributes": ['id="<&>xml:id<;>"'],
        "pieces": [["{caption_like_heading}", ""], ["{captiontext}",""]]
   //     "pieces": [["(literal, caption goes here)",""]]
    },
    "pretext": {
        "tag": "caption",
        "attributes": [],
        "pieces": [["captiontext", ""]]
    },
    "source": {
        "pieces": [["content", ""]]
    }
  },
  "captiontext": {  /* not used */
    "html": {
        "tag": "p",
        "data_editable": "321",
   //     "attributes": ['id="<&>xml:id<;>"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"'],
// do it like editabe title?
        "attributes": ['data-source_id="<&>xml:id<;>"', 'data-component="caption"', 'class="caption"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"'],
        "pieces": [["captiontext",""]]
    },
    "pretext": {
        "tag": "",
        "attributes": [],
        "pieces": [["captiontext", ""]]
    },
    "source": {
        "pieces": [["captiontext", ""]]
    }
  },

  "references": {
    "html": {
        "tag": "article",
        "cssclass": "bib",
        "data_editable": "33",
        "attributes": ['id="<&>xml:id<;>"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"', 'class="<&>{cssclass}<;>"'],
        "pieces": [["{section_like_heading}", ""], ["content",""]]
    },
    "pretext": {
        "tag": "references",
        "attributes": ['xml:id="<&>xml:id<;>"'],
        "pieces": [["title", ""], ["content",""]]
    },
    "source": {
        "pieces": [["title", ""], ["content",""]]
    }
  },

/* biblio, the items directly following it, and the refrences above,
   are not usable at this time.  references have to be handled in
   a text editor.  3 Dec 2021
*/
  "biblio": {
    "html": {
        "tag": "div",
        "cssclass": "bibentry",
        "data_editable": "333",
        "attributes": ['id="<&>xml:id<;>"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"', 'class="<&>{cssclass}<;>"'],
        "pieces": [["{bib-title}", ""], ["{journal}",""], ["{volume}",""], ["{number}",""], ["{author}",""], ["{pages}",""]]
    },
    "pretext": {
        "tag": "biblio",
        "attributes": ['xml:id="<&>xml:id<;>"', 'type="raw"'],
        "pieces": [["title", ""], ["journal",""], ["volume",""], ["number",""], ["author",""], ["pages",""]]
    },
    "source": {
        "pieces": [["title", ""], ["journal",""], ["volume",""], ["number",""], ["author",""], ["pages",""]]
    }
  },

  "bib-title": {
    "html": {
        "tag": "i",
        "pieces": [["title", "zz"]]
    }
  },
  "author": {
    "html": {
        "tag": "",
        "pieces": [["author", ""], ["{comma}", ""]]
    }
  },
  "journal": {
    "html": {
        "tag": "",
        "pieces": [["journal", ""]]
    }
  },
  "volume": {
    "html": {
        "tag": "b",
        "pieces": [["volume", ""]]
    }
  },
  "pages": {
    "html": {
        "tag": "jjj",
        "pieces": [["pages", ""]]
    }
  },
  "number": {
    "html": {
        "tag_opening": "no. ",
        "tag_closing": " ",
        "pieces": [["number", ""]]
    }
  },

  "remark-like": {
    "html": {
        "tag": "article",
        "cssclass": "remark-like",
        "data_editable": "92",
        "attributes": ['id="<&>xml:id<;>"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"', 'class="<&>{cssclass}<;>"'],
        "pieces": [["{theorem_like_heading}", ""], ["statement",""]]
    },
    "pretext": {
        "attributes": ['xml:id="<&>xml:id<;>"'],
        "pieces": [["title", "title"], ["statement", "statement"]]
    },
    "source": {
        "pieces": [["title", ""], ["statement", "p"]]
    }
  },

  "project-like-tasks": {
    "html": {
        "tag": "article",
        "attributes": ['id="<&>xml:id<;>"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"', 'class="<&>{cssclass}<;>"'],
        "cssclass": "project-like",
        "data_editable": "194",
        "pieces": [["{theorem_like_heading}", ""], ["content",""], ["tasks", ""]]
    },
    "pretext": {
        "tag": "sourcetag",
        "pieces": [["title", "title"], ["content", ""], ["tasks", ""]],
        "attributes": ['xml:id="<&>xml:id<;>"']
    },
    "source": {
        "pieces": [["title", ""], ["content", "p"], ["tasks", ""]]
 //       "attributes": [["workspace", "0"]]
    }
  },
  "project-like": {
    "html": {
        "tag": "article",
        "attributes": ['id="<&>xml:id<;>"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"', 'class="<&>{cssclass}<;>"'],
        "cssclass": "project-like",
        "data_editable": "94",
        "pieces": [["{theorem_like_heading}", ""], ["statement",""], ["%hint%", "hint"], ["%answer%", "answer"], ["%solution%", "solution"], ["{workspace}", ""]]
    },
    "pretext": {
        "tag": "sourcetag",
        "pieces": [["title", "title"], ["statement", "statement"], ["hint", "hint"], ["answer", "answer"], ["solution", "solution"]],
        "attributes": ['xml:id="<&>xml:id<;>"', 'workspace="<&>workspace<;>"']
    },
    "source": {
        "pieces": [["title", ""], ["statement", "p"], ["hint", ""], ["answer", ""], ["solution", ""]],
        "attributes": [["workspace", "0"]]
    }
  },

  "definition-like": {
    "html": {
        "tag": "article",
        "cssclass": "definition-like",
        "data_editable": "95a",
        "pieces": [["{theorem_like_heading}", ""], ["statement", ""]],
        "attributes": ['id="<&>xml:id<;>"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"', 'class="<&>{cssclass}<;>"']
    },
    "pretext": {
        "attributes": ['xml:id="<&>xml:id<;>"'],
        "pieces": [["title", "title"], ["statement", "statement"]]
    },
    "source": {
        "pieces": [["title", ""], ["statement", "p"]]
    }
  },

  "theorem-like": {
    "html": {
        "tag": "article",
        "cssclass": "theorem-like",
        "data_editable": "93",
        "pieces": [["{theorem_like_heading}", ""], ["statement", ""], ["{proof}", ""]],
        "attributes": ['id="<&>xml:id<;>"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"', 'class="<&>{cssclass}<;>"']
    },
    "pretext": {
        "attributes": ['xml:id="<&>xml:id<;>"'],
        "pieces": [["title", "title"], ["statement", "statement"], ["{proof}", ""]]
    },
    "source": {
        "pieces": [["title", ""], ["statement", "p"], ["proof", ""]]
    }
  },

  "task": {
    "html": {
        "tag": "article",
        "cssclass": "exercise-like task",
        "data_editable": "94ZZZA",
        "attributes": ['id="<&>xml:id<;>"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"', 'class="<&>{cssclass}<;>"'],
        "pieces": [["{task_like_heading}", ""], ["statement",""], ["%hint%", "hint"], ["%answer%", "answer"], ["%solution%", "solution"], ["{workspace}", ""]]
    },
    "pretext": {
        "tag": "task",
        "pieces": [["title", "title"], ["statement", "statement"], ["hint", ""], ["answer", ""], ["solution", ""]],
        "attributes": ['workspace="<&>workspace<;>"']
    },
    "source": {
        "pieces": [["title", ""], ["statement", "p"], ["hint", ""], ["answer", ""], ["solution", ""]],
        "attributes": [["workspace", "0"]]
    }
  },

/* consolidate H/A/S */
  "hint": { 
    "html": {
        "tag": "article",
        "cssclass": "solution-like hint",
        "attributes": ['id="<&>xml:id<;>"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"', 'class="<&>{cssclass}<;>"'],
        "pieces": [["{proof_like_heading}", ""], ["content",""]],
// go back and make the lack of data_editable automatically make the contained p editable
/*        "data_editable": "454", */
        "data_editable": "hhhh"
    },
    "pretext": {
        "tag": "hint",
        "attributes": ['xml:id="<&>xml:id<;>"'],
        "pieces": [["title", "title"], ["content", ""]]
    },
    "source": {
        "pieces": [["content", "p"]]
    }
  },
  "answer": { 
    "html": {
        "tag": "article",
        "cssclass": "solution-like answer",
        "attributes": ['id="<&>xml:id<;>"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"', 'class="<&>{cssclass}<;>"'],
        "pieces": [["{proof_like_heading}", ""], ["content",""]],
// go back and make the lack of data_editable automatically make the contained p editable
/*        "data_editable": "454", */
        "data_editable": "hhhh"
    },
    "pretext": {
        "tag": "answer",
        "attributes": ['xml:id="<&>xml:id<;>"'],
        "pieces": [["title", "title"], ["content", ""]]
    },
    "source": {
        "pieces": [["content", "p"]]
    }
  },
  "solution": {
    "html": {
        "tag": "article",
        "cssclass": "solution-like solution",
        "attributes": ['id="<&>xml:id<;>"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"', 'class="<&>{cssclass}<;>"'],
        "pieces": [["{proof_like_heading}", ""], ["content",""]],
// go back and make the lack of data_editable automatically make the contained p editable
/*        "data_editable": "454", */
        "data_editable": "hhhh"
    },
    "pretext": {
        "tag": "solution",
        "attributes": ['xml:id="<&>xml:id<;>"'],
        "pieces": [["title", "title"], ["content", ""]]
    },
    "source": {
        "pieces": [["content", "p"]]
    }
  },

  "workspace": {
    "html": {
        "tag": "div",
        "cssclass": "workspace",
        "data_editable": "WwW",
        "attributes": ['data-parent_id="<&>xml:id<;>"', 'data-space="<&>workspace<;>"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"', 'class="<&>{cssclass}<;>"'],
        "pieces": []
    }
  },

  "term": {    // need to mark it as inline
      "html": {
          "tag": "dfn",
          "attributes": ['id="<&>xml:id<;>"', 'class="terminology"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"'],
          "data_editable": "ttt",
          "pieces": [["content", ""]]
      },
      "pretext": {
          "tag": "term",
          "pieces": [["content", ""]]
      },
      "source": {
          "pieces": [["content", ""]]
      }
  },

  "em": {    // need to mark it as inline
      "html": {
          "tag": "em",
          "attributes": ['id="<&>xml:id<;>"', 'class="emphasis"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"'],
          "data_editable": "eemm",
          "pieces": [["content", ""]]
      },
      "pretext": {
          "tag": "em",
          "pieces": [["content", ""]]
      },
      "source": {
          "pieces": [["content", ""]]
      }
  },
  "fn": {    // need to mark it as inline
      "html": {
          "tag": "a",
          "attributes": ['id="<&>xml:id<;>"', 'class="id-ref fn-knowl original"', 'data-knowl=" "', 'href=" "', 'data-refid="hk-<&>xml:id<;>"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"'],
          "data_editable": "fnfnfn",
//          "pieces": [["content", "sup"]]
          "pieces": [["(literal,footnote)", "sup"]]
      },
      "pretext": {
          "tag": "fn",
          "attributes": ['xml:id="<&>xml:id<;>"'],
          "pieces": [["content", ""]]
      },
      "source": {
          "pieces": [["content", ""]]
      }
  },
  "alert": {    // need to mark it as inline
      "html": {
          "tag": "em",
          "attributes": ['id="<&>xml:id<;>"', 'class="alert"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"'],
          "data_editable": "aall",
          "pieces": [["content", ""]]
      },
      "pretext": {
          "tag": "alert",
          "pieces": [["content", ""]]
      },
      "source": {
          "pieces": [["content", ""]]
      }
  },
  "init": {    // need to mark it as inline
      "html": {
          "tag": "abbr",
          "attributes": ['id="<&>xml:id<;>"', 'class="initialism"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"'],
          "data_editable": "iinniitt",
          "pieces": [["content", ""]]
      },
      "pretext": {
          "tag": "init",
          "pieces": [["content", ""]]
      },
      "source": {
          "pieces": [["content", ""]]
      }
  },
  "c": {    // need to mark it as inline
      "html": {    
          "tag": "code",
          "attributes": ['id="<&>xml:id<;>"', 'class="code-inline tex2jax_ignore"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"'],
          "data_editable": "ccoo",
          "pieces": [["content", ""]]
      },   
      "pretext": {
          "tag": "c",
          "pieces": [["content", ""]]
      },
      "source": {
          "pieces": [["content", ""]]
      }
  },

  "ellipsis": {    // need to mark it as inline
      "html": {
          "tag": "span",
          "attributes": ['id="<&>xml:id<;>"', 'class="abbrev"', 'contenteditable="false"'],
          "data_editable": "abbr",
          "pieces": [["(literal,&hellip;)", ""]]
      },
      "pretext": {
          "tag": "ellipsis",
           "pieces": []
      },
      "source": {
      }
  },
  "etc": {    // need to mark it as inline
      "html": {
          "tag": "span",
          "attributes": ['id="<&>xml:id<;>"', 'class="abbrev"', 'contenteditable="false"'],
          "pieces": [["(literal,etc)", ""]]
      },
      "pretext": {
          "tag": "etc",
           "pieces": []
      },
      "source": {
      }
  },

  "q": {    // need to mark it as inline
      "html": {
          "tag": "q",
          "attributes": ['id="<&>xml:id<;>"', 'class="quote"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"'],
          "data_editable": "qqq",
          "pieces": [["content", ""]]
      },
      "pretext": {
          "tag": "q",
          "pieces": [["content", ""]]
      },
      "source": {
          "pieces": [["content", ""]]
      }
  },

  "m": {    // need to mark it as inline
      "html": {
          "tag_opening": "<span class='process-math'>\\(",
          "tag_closing": "\\)</span>",
 //         "tag": "script",
    //      "attributes": ['type="math/tex"'],
          "pieces": [["content", ""]]
      },
      "pretext": {
          "tag": "m",
          "pieces": [["content", ""]]
      },
      "source": {
          "pieces": [["content", ""]]
      }
  },

  "me": {
      "html": {
          "tag": "div",
          "attributes": ['id="<&>xml:id<;>"', 'class="displaymath process-math"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"'],
          "data_editable": "42",
          "pieces": [["{me_raw}", ""]]
      },
      "pretext": {
          "tag": "me",
          "attributes": ['xml:id="<&>xml:id<;>"'],
          "pieces": [["content", ""]]
      },
      "source": {
          "pieces": [["content", ""]]
      }
  },
  "men": {
      "html": {
          "tag": "div",
          "attributes": ['id="<&>xml:id<;>"', 'class="displaymath process-math"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"'],
          "data_editable": "42",
          "pieces": [["{me_raw}", ""]]
      },
      "pretext": {
          "tag": "men",
          "attributes": ['xml:id="<&>xml:id<;>"'],
          "pieces": [["content", ""]]
      },
      "source": {
          "pieces": [["content", ""]]
      }
  },
  "md": {
      "html": {
          "tag": "div",
          "attributes": ['id="<&>xml:id<;>"', 'class="displaymath process-math"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"'],
          "data_editable": "42",
          "pieces": [["{md_raw}", ""]]
      },
      "pretext": {
          "tag": "md",
          "attributes": ['xml:id="<&>xml:id<;>"'],
          "pieces": [["content", ""]]
      },
      "source": {
          "pieces": [["content", ""]]
      }
  },
  "mdn": {
      "html": {
          "tag": "div",
          "attributes": ['id="<&>xml:id<;>"', 'class="displaymath process-math"', 'data-editable="<&>{data_editable}<;>"', 'tabindex="-1"'],
          "data_editable": "42",
          "pieces": [["{me_raw}", ""]]
      },
      "pretext": {
          "tag": "mdn",
          "attributes": ['xml:id="<&>xml:id<;>"'],
          "pieces": [["content", ""]]
      },
      "source": {
          "pieces": [["content", ""]]
      }
  },
  "me_raw": {
      "html": {
          "tag_opening": "\\begin{equation*}",
          "tag_closing": "\\end{equation*}",
          "pieces": [["content", ""]]
      }
  },
  "md_raw": {
      "html": {
          "tag_opening": "\\begin{align*}",
          "tag_closing": "\\end{align*}",
          "pieces": [["content", ""]]
      }
  },
// check if mrow is actually used
  "mrow": {
      "html": {
          "tag_opening": "",
          "tag_closing": "\\cr",
          "data_editable": "422",
          "pieces": [["content", ""]]
      },
      "pretext": {
          "tag": "mrow",
          "attributes": ['xml:id="<&>xml:id<;>"'],
          "pieces": [["content", ""]]
      },
      "source": {
          "pieces": [["content", ""]]
      }
  }

}

var environment_instances = {
    "definition-like": ["definition", "conjecture", "axiom", "principle", "heuristic", "hypothesis", "assumption"],
    "theorem-like": ["lemma", "proposition", "theorem", "corollary", "claim", "fact", "identity", "algorithm"],
    "remark-like": ["remark", "warning", "note", "observation", "convention", "insight"],
    "project-like-tasks": ["investigation", "exploration", "project"],
    "project-like": ["exercise", "activity"]
}

for (const [owner, instances] of Object.entries(environment_instances)) {
    var data_editable_base = objectStructure[owner].html.data_editable;
    var cssclass_base = objectStructure[owner].html.cssclass;
    var source_pieces = objectStructure[owner].source.pieces;
    var pretext_pieces = objectStructure[owner].pretext.pieces;
    var pretext_attributes = (objectStructure[owner].pretext.attributes || []);
    var source_attributes = (objectStructure[owner].source.attributes || []);
    for (var j=0; j < instances.length; ++j) {
        var this_tag = instances[j];
        objectStructure[this_tag] = {
            "owner": owner,
            "html": {
                "tag":  objectStructure[owner].html.tag,
                "pieces": objectStructure[owner].html.pieces,
                "attributes": objectStructure[owner].html.attributes,
                "cssclass": cssclass_base + " " + this_tag,
                "data_editable": data_editable_base + j.toString(),
                "heading": objectStructure[owner].html.heading
            },
            "pretext": {
                "tag": this_tag,
                "pieces": pretext_pieces,
                "attributes": pretext_attributes
            },
            "source": {
                "tag": this_tag,
                "pieces": source_pieces,
                "attributes": source_attributes
            }
        }
    }
}

editorLog('objectStructure["exercise"]', objectStructure["exercise"]);

var sidebyside_instances = {
"sbs": [["2 panels", "sbs2"], ["3 panels", "sbs3"], ["4 panels", "sbs4"]],
//"sbs2": [["full across XX", "sbs2_0_50_50_0"], ["gap but no margin", "sbs2_0_40_40_0"], ["spaced equally", "sbs2_5_40_40_5"]],
"sbs2": [["full across", "sbs_0_50_50_0"], ["gap but no margin", "sbs_0_45_45_0"], ["spaced equally", "sbs_5_40_40_5"]],
"sbs3": [["full across", "sbs_0_34_32_34_0"], ["gap but no margin", "sbs_0_28_28_38_0"], ["spaced equally", "sbs_5_25_26_25_5"]],
"sbs4": [["full across", "sbs_0_25_25_25_25_0"], ["gap but no margin", "sbs_0_20_20_20_20_0"], ["spaced equally", "sbs_3_18_18_18_18_3"]]
}

Object.assign(objectStructure, sidebyside_instances);

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

function rescale(width, max, margin_left, margin_right) {
    var available_width = max - parseFloat(margin_left) - parseFloat(margin_right);
    return width * 100 / available_width
}

function spacemath_to_tex(text) {
    thetext = text;

    thetext = thetext.replace(/ d([a-zA-Z])(\s|$)/, " \\,d$1$2");
    thetext = thetext.replace(/ *< */, " &lt; ");

    return thetext
}

function split_paragraphs(paragraph_content) {

    // does the textbox contain more than one paragraph?
    var paragraph_content_list = paragraph_content.split("<div><br></div>");
    editorLog("there were", paragraph_content_list.length, "paragraphs, but some may be empty");
    for (var j=0; j < paragraph_content_list.length; ++j) {
        editorLog("paragraph", j, "begins", paragraph_content_list[j].substring(0,20))
    }   

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
        if (!this_paragraph_contents_raw) { editorLog("empty paragraph") }
        else { paragraph_content_list_trimmed.push(this_paragraph_contents_raw) }
        editorLog("this_paragraph_contents_raw", this_paragraph_contents_raw);
    }   

    if (!paragraph_content_list_trimmed.length ) { 
            // empty, so insert it and delete it later
        paragraph_content_list_trimmed = [""];
    }   

    return paragraph_content_list_trimmed
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

Object.assign(submenu_options, sidebyside_instances);

Object.assign(submenu_options, environment_instances);  // wrong because string not list
                           // or not wrong, if the code is more clever

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


//  not currently used
function past_edits() {

    var the_past_edits = [];
    if(recent_editing_actions.length) {
         the_past_edits = recent_editing_actions.map(x => [x.join(" ")])}
    else { the_past_edits = [["no chnages yet"]] }

    return the_past_edits
}

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

function make_current_editing_tree_from_id(theid) {

//current_editing keeps track of where we are in the tree.  maybe need a better name?

    editorLog("     OOOOO make_current_editing_tree_from_id", theid);
    editorLog("     which has internalSource", internalSource[theid]);
    editorLog("     within", internalSource);
    editorLog("     and the DOM object is", document.getElementById(theid));
    // the existing current_editing know the top level id
//    var top_id = current_editing["tree"][0][0].id;
    var top_id = top_level_id;

    // but now we need to start over and go bottom-up
    current_editing = {
            "level": -1,
            "location": [],
            "tree": [ ]
        }

    var current_id = theid;
    var current_element = document.getElementById(current_id);
    console.log("current_id", current_id, "current_element", current_element);
    var selectable_parent, current_element_siblings, selectable_parent_id;
    var ct=0;
    while (current_id != top_id && ct < 10) {
        ct += 1;
        editorLog("ct", ct);
        editorLog("looking to match current_element", current_element, "until we hit", top_id);
        selectable_parent = current_element.parentElement.closest("[data-editable]");
        current_element_siblings = next_editable_of(selectable_parent, "children");
        current_id = selectable_parent.id;
        editorLog("current_id", current_id);
        current_editing["tree"].unshift(current_element_siblings);
        editorLog("looking for", current_element, "in", current_element_siblings);
        for (var j=0; j < current_element_siblings.length; ++j) {
            if (current_element == current_element_siblings[j]) {
                current_editing["level"] += 1;
                current_editing["location"].unshift(j);
                editorLog("this is item", j);
                break
            } else {
                editorLog(current_element == current_element_siblings[j], "aaa", current_element,"zzz", current_element_siblings[j])
            }
        }
        current_element = selectable_parent
    }
    current_editing["level"] += 1;
    current_editing["location"].unshift(0);
    current_editing["tree"].unshift([document.getElementById(top_id)]);

    editorLog("built current_editing after", ct, "levels");
    editorLog("current_editing[level]", current_editing["level"]);
    editorLog("current_editing[location]", current_editing["location"]);
    editorLog("current_editing[tree]", current_editing["tree"])

    editorLog("     OOOOO   done with  make_current_editing_tree_from_id", theid, document.getElementById(theid));

}

function standard_title_form(object_id) {
    var the_object = internalSource[object_id];
    var the_title = the_object.title;

    var title_form = '<span id="actively_editing" class="starting_point_for_editing" data-source_id="' + object_id + '" data-component="' + 'title' + '" contenteditable="true">' + the_title + '</span>';

    return title_form
}
function standard_caption_form(object_id) {
    var the_object = internalSource[object_id];
    editorLog("editing caption of object_id", object_id, "which contains", the_object);
    var the_caption = the_object.caption;

    var caption_form = '<span id="actively_editing" class="starting_point_for_editing" data-source_id="' + object_id + '" data-component="' + 'caption' + '" contenteditable="true">' + the_caption + '</span>';

    return caption_form
}


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
             if (i==0) { this_menu += ' id="choose_current"'}
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
             if (i==0) { this_menu += ' id="choose_current"'}
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
             if (i==0) { this_menu += ' id="choose_current"'}
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
         if (i==0) { this_menu += ' id="choose_current"'}
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
        
        this_list = '<li tabindex="-1" id="choose_current" data-env="p" data-action="edit">Change the title</li>';
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
            this_list = '<li tabindex="-1" id="choose_current" data-env="p" data-action="edit">Edit ' + this_obj_environment + '</li>';
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
            this_list = '<li tabindex="-1" id="choose_current" data-env="imagebox" data-action="modify">Modify layout<div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div></li>';
        } else if (this_obj.classList.contains("sbspanel")) {
            this_list = '<li tabindex="-1" id="choose_current" data-env="sbspanel" data-action="modify">Modify layout<div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div></li>';
        } else {
            this_list += '<li tabindex="-1" id="choose_current" data-env="' + this_object_type + '" data-location="enter">Enter ' + this_obj_environment + '</li>';
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

    console.log("this_obj_or_id", this_obj_or_id, typeof this_obj_or_id);
    if (typeof this_obj_or_id === 'string') {
        this_obj = document.getElementById(this_obj_or_id)
    } else {
        this_obj = this_obj_or_id
    }
    console.log("this_obj", this_obj);
    var this_id = this_obj.id;
//    this_obj = document.getElementById(this_obj);  // because is is an id?  Maybe need cases here

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
    edit_menu_holder.setAttribute('class', 'edit_menu_holder');
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
            edit_option.setAttribute('class', 'edit_menu');
            this_obj_parent_id = this_obj.parentElement.parentElement.id;
            this_obj_environment = internalSource[this_obj_parent_id]["sourcetag"];
            edit_option.innerHTML = '<li id="choose_current" tabindex="-1" data-action="change-env">Change "' + this_obj_environment + '" to <div class="wrap_to_submenu"><span class="to_submenu">&#9659;</span></div></li>';
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
            edit_option.setAttribute('class', 'edit_menu');
            editorLog("this_obj", this_obj);
            editorLog("this_obj.innerHTML", this_obj.innerHTML);
            editorLog("menu only?", this_obj.innerHTML == '<div id="edit_menu_holder" class="edit_menu_holder" tabindex="-1"></div>');
            this_obj_parent_id = this_obj.parentElement.parentElement.id;
            this_obj_environment = internalSource[this_obj_parent_id]["sourcetag"];
            if (this_obj.innerHTML == '<div id="edit_menu_holder" class="edit_menu_holder" tabindex="-1"></div>') {
                edit_option.innerHTML = '<li id="choose_current" tabindex="-1" data-action="change-' + this_contained_type + '">Add a ' + this_contained_type + '</li>';
            } else {
                edit_option.innerHTML = '<li id="choose_current" tabindex="-1" data-action="change-' + this_contained_type + '">Change ' + this_contained_type + '</li>';
            }
            edit_option.setAttribute('data-location', 'inline');
        } else if ((this_obj.classList.contains("placeholder") && (this_obj.classList.contains("hint") ||
                  this_obj.classList.contains("answer") ||
                  this_obj.classList.contains("solution") ||
                  this_obj.classList.contains("proof")) ) ) {
            var theverb = "add"
            var thenoun = this_obj.getAttribute("data-HAS");
            edit_option.setAttribute('id', 'choose_current');
            edit_option.setAttribute('data-env', thenoun);
            edit_option.setAttribute('data-parent_id', this_obj.getAttribute("data-parent_id"));
            edit_option.innerHTML = "<b>" + theverb + "</b>" + " " + thenoun;
        } else if (this_obj.classList.contains('workspace')) {
            edit_option.setAttribute('id', 'choose_current');
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

function create_new_internal_object(new_tag, new_id, parent_description) {

    var new_source = {"xml:id": new_id, "sourcetag": new_tag, "parent": parent_description, "title": ""}

    editorLog("create new internal object", new_tag, "new_id", new_id, "parent_description", parent_description);
    editorLog("within", internalSource[parent_description[0]]);
    if (new_tag.startsWith("sbs")) {  // creating an sbs, which contains one sbsrow, which contains several sbspanels
        new_source.sourcetag = "sidebyside";
        var sbs_layout = new_tag.split("_");
        var [margin_left, margin_right] = [sbs_layout[1], sbs_layout[sbs_layout.length - 1]];
        editorLog("sbs side margins", margin_left, "jj", margin_right);
        new_source.marginleft = margin_left;
        new_source.marginright = margin_right;

        var col_content = "";
        var widths = [];
        for (var j=2; j <= sbs_layout.length - 2; ++j) {
            widths.push(sbs_layout[j]);
            var new_col_id = randomstring();
            col_content += "<&>" + new_col_id + "<;>";
            internalSource[new_col_id] = {"xml:id": new_col_id, "sourcetag": "sbspanel",
                "content": "", "parent": [new_id, "content"]}
        }
        new_source.widths = widths;
        new_source.content = col_content;

        editorLog("new sbs", new_source);

    } else {

      editorLog("new_tag", new_tag);
      var thisstructure = objectStructure[new_tag];
      var thisownersourcestructure = {};
      if (!thisstructure) { errorLog(new_tag + " not implemented yet"); return "" }
      if ("owner" in thisstructure) {
          var thisownerstructure = objectStructure[thisstructure.owner];
          thisownersourcestructure = thisownerstructure.source;
      }
      var thissourcestructure = Object.assign({},thisownersourcestructure, thisstructure.source);

      editorLog("thissourcestructure", thissourcestructure);

      if ("attributes" in thissourcestructure) {
          these_source_attributes = thissourcestructure.attributes;
          for (var j=0; j < these_source_attributes.length; ++j) {
          editorLog("adding", j, "attribute", these_source_attributes[j]);
              new_source[these_source_attributes[j][0]] = these_source_attributes[j][1]
          }
      }

/* here need to also use the owner structure */
      var these_source_pieces = thissourcestructure.pieces;
      for (var j=0; j < these_source_pieces.length; ++j) {
          editorLog("adding a piece", these_source_pieces[j]);
          var [this_piece, this_piece_contains] = these_source_pieces[j];

              if (this_piece_contains) {
                  var new_child_id = randomstring();
                  new_source[this_piece] = "<&>" + new_child_id + "<;>";
                  create_new_internal_object(this_piece_contains, new_child_id, [new_id, this_piece]);
              } else {
                  new_source[this_piece] = ""
              }
      }
    }

    editorLog("made the new_source", new_source);

    internalSource[new_id] = new_source;

    editorLog("parent_description", parent_description, "new_tag", new_tag, "new_id", new_id);
    editorLog("internalSource", internalSource);
    if (new_tag == "list") {
        // do nothing, because it is the child "li" which we are really creating
        // chack that:  maybe do add, if the stack is in the proper order
    } else if (tag_type(new_tag) == "p"){
        // p is the default, so no need to keep track of it
    } else if (new_tag == "source"){
       // not really a tag 
    } else if (new_tag.startsWith("sbs")){
        ongoing_editing_actions.push(["new", "sbs", new_id]);
    } else {
        ongoing_editing_actions.push(["new", new_tag, new_id]);
    }
  return new_tag
}

function show_source(sibling, relative_placement) {
//    var current_source = document.getElementById("newpretextsource");
//    if (current_source) { editorLog("curr sou", current_source); alert("curr sour"); current_source.remove() }
    var edit_placeholder = document.createElement("span");
    edit_placeholder.setAttribute('id', "newsource");
    sibling.insertAdjacentElement(relative_placement, edit_placeholder);

    editorLog("just added", edit_placeholder);

    var the_pretext_source =  output_from_id("", top_level_id, "pretext");

    the_pretext_source = the_pretext_source.replace(/\n\n/g, '\n');

    // remove temporary ids
    the_pretext_source = the_pretext_source.replace(/ xml:id="tMP[0-9a-z]+"/g, '');
    the_pretext_source = the_pretext_source.replace(/^ +$/mg, '');  // m = multiline

//    var the_old_source = document.getElementById("newsource");
//    if (the_old_source) { the_old_source.remove() }
    edit_placeholder.insertAdjacentHTML('afterend', '<textarea id="newpretextsource" style="width: 100%; height:30em">' + the_pretext_source + '</textarea>');
}

// unify with show_source, and maybe make the clean up part of output_from_id
function save_source() {
//    var current_source = document.getElementById("newpretextsource");
//    if (current_source) { editorLog("curr sou", current_source); alert("curr sour"); current_source.remove() }
    editorLog("         QQ  saving");

    var the_pretext_source =  output_from_id("", top_level_id, "pretext");

    the_pretext_source = the_pretext_source.replace(/\n\n/g, '\n');
    // remove temporary ids
    the_pretext_source = the_pretext_source.replace(/ xml:id="tMP[0-9a-z]+"/g, '');
    the_pretext_source = the_pretext_source.replace(/^ +$/mg, '');  // m = multiline

    editorLog("         RR  saving", top_level_id, "which begins", the_pretext_source.substring(0,50));
    parent.save_file(top_level_id, the_pretext_source)
}

function create_object_to_edit(new_tag, new_objects_sibling, relative_placement) {

    // when relative_placement is "afterbegin", the new_objects_sibling is actually its parent
    editorLog("create object to edit", new_tag, new_objects_sibling, relative_placement);
              // first insert a placeholder to edit-in-place
    var new_id = randomstring();
    recent_editing_actions.push(["new", new_tag, new_id]);
        // we won;t need all of these, so re-think when these are created
    var edit_placeholder = document.createElement("span");
    edit_placeholder.setAttribute('id', new_id);

        // when adding an li, you are actually focused on somethign inside an li
        // but, maybe that distinction shoud be mede before calling create object to edit ?
    if (new_tag == "li") { new_objects_sibling = new_objects_sibling.parentElement }

    var sibling_id, parent_description, object_neighbor;

    if (["hint", "answer", "solution", "proof"].includes(new_tag)) {   // this is only for the case that a solution does not already exist
// create_new

        sibling_id = new_objects_sibling.parentElement.id;
        parent_description = [sibling_id, new_tag]

        editorLog(new_tag, "parent_description", parent_description);
        object_neighbor = "" ; // will not be used

    } else if(new_objects_sibling.classList.contains("sbspanel")) {  //bad hack!  use internalCOntents!
        sibling_id = new_objects_sibling.id;
        editorLog("special case for empty sbspanel",sibling_id);
 //       alert("special sbspanel case");
        parent_description = [sibling_id, "content"]
        object_neighbor = "" ; // will not be used???
    } else {
                  // and describe where it goes
        editorLog("new_objects_sibling",new_objects_sibling);
        sibling_id = new_objects_sibling.id;
        parent_description = internalSource[sibling_id]["parent"];
        object_neighbor = new RegExp('(<&>' + sibling_id + '<;>)');
    }

    if (relative_placement == "afterbegin" && new_tag != "image") {  // when adding to a sbs panel
                           // redo the condition so that it explicitly uses sbs
       // redundant with the "special case" above?
  //      parent_description = [new_id, "content"];
    }
    var object_neighbor = new RegExp('(<&>' + sibling_id + '<;>)');
    if (new_tag == "task" && !(new_objects_sibling.classList.contains("task"))) {
      // when task is being added by selecting from the parent exercise
        relative_placement = "atend";
        parent_description = [sibling_id, "tasks"];
    }
    if (["hint", "answer", "solution", "proof"].includes(new_tag)) {   // this is only for the case that a solution does not already exist
        relative_placement = "replace";
    }
    editorLog(new_tag, "parent_description", parent_description);

                  // then create the empty internalSource for the new object
    var new_obj = create_new_internal_object(new_tag, new_id, parent_description);
    if (!new_obj) { return "" }

   // we have made the new object, but we still have to put it in the correct location

    var the_current_arrangement = internalSource[parent_description[0]][parent_description[1]];
    editorLog("         the_current_arrangement", the_current_arrangement);
    editorLog("         from parent_description", parent_description, "internalSource[parent_description[0]]", internalSource[parent_description[0]]);
    editorLog("    current_editing", current_editing);

// maybe the changes to current_editing is different for lists?

    var neighbor_with_new = '';
    var current_level = current_editing["level"];
    var current_location = current_editing["location"][current_level];
    editorLog("  UUU  current_editing", current_editing["level"], current_editing["location"].length, current_editing["tree"].length, current_editing["tree"][current_editing["level"]])
    if (relative_placement == "beforebegin" || relative_placement == "afterbegin") {  
        neighbor_with_new = '<&>' + new_id + '<;>' + '$1';
    }
    else if (relative_placement == "afterend" || relative_placement == "beforeend"){
        neighbor_with_new = '$1' + '<&>' + new_id + '<;>'
        current_location += 1
    }
    editorLog("makking new_arrangement from", object_neighbor, "by", neighbor_with_new);

    if (relative_placement == "atend" || relative_placement == "replace" ) {
   // this is not quire gight, but it works for hint/answer/solution
        new_arrangement = the_current_arrangement + '<&>' + new_id + '<;>';
    } else if(the_current_arrangement) {
        new_arrangement = the_current_arrangement.replace(object_neighbor, neighbor_with_new);
    } else {
        new_arrangement = '<&>' + new_id + '<;>';
    }
    editorLog("which became", new_arrangement);
//    alert("here");
    internalSource[parent_description[0]][parent_description[1]] = new_arrangement;
    if (new_tag == "list") {
  //      current_editing["level"] += 1;
  //      current_editing["location"].push(0);
  //      current_editing["tree"].push([document.getElementById(new_p_id)])
    }  else {
        current_editing["location"][current_level] = current_location;
    }
    editorLog("         new_arrangement", new_arrangement);
    editorLog("tried to insert", new_id, "next to", sibling_id, "in", the_current_arrangement)
    editorLog("    updated current_editing", current_editing);
    editorLog("  VVV  current_editing", current_editing["level"], current_editing["location"].length, current_editing["tree"].length, current_editing["tree"][current_editing["level"]])
    editorLog("relative_placement", relative_placement, "edit_placeholder", edit_placeholder);

     if (relative_placement == "atend") {
        new_objects_sibling.insertAdjacentElement("beforeend", edit_placeholder);
     } else if (relative_placement == "replace") {
        new_objects_sibling.replaceWith(edit_placeholder);
    } else {
        new_objects_sibling.insertAdjacentElement(relative_placement, edit_placeholder);
    }

    return edit_placeholder
}

function edit_in_place(obj, oldornew) {
    // currentlt old_or_new is onlu use as "new" for a new li, so that we know
    // to immediately make a new li to edit
         // previous comment probebly wrong/out of date

    var thisID;
    editorLog("in edit in place", obj);
    if (thisID = obj.getAttribute("id")) {
        editorLog("will edit in place id", thisID, "which is", obj);
        thisTagName = obj.tagName.toLowerCase();
    } else {  // editing somethign without an id, so probably is a title or caption
        if (obj.classList.contains("heading")) {
            editorLog("changing a heading");
            editorLog("except we don;t know how to do that")
        } else {
            errorLog("error:  I don't know how to edit", obj)
        }
        return ""
    }

     // this only works for paragraphs,
     // which may be right, because existing content is mostly titles and paragraphs
    if ( internalSource[thisID] ) {
      var new_tag = internalSource[thisID]["sourcetag"];
      var new_id = thisID;  // track down why new_id is in the code
      editorLog("new_tag is", new_tag, "from thisID", thisID, "from", internalSource[thisID]);
      if (tag_type(new_tag) == "p" || tag_type(new_tag) == "md") {  // make into a category?
        var this_content_container = document.createElement('div');
        this_content_container.setAttribute('id', "actively_editing");
        this_content_container.setAttribute('data-age', oldornew);
        editorLog("thing with thisID", thisID, "is",document.getElementById(thisID));
        $("#" + thisID).replaceWith(this_content_container);

        var idOfEditText = 'editing' + '_input_text';
        var paragraph_editable = document.createElement('div');
        paragraph_editable.setAttribute('contenteditable', 'true');
        if (tag_type(new_tag) == "md") {
            paragraph_editable.setAttribute('class', 'text_source displaymath_input');
        } else {
            paragraph_editable.setAttribute('class', 'text_source paragraph_input');
        }
        paragraph_editable.setAttribute('id', idOfEditText);
        paragraph_editable.setAttribute('data-source_id', thisID);
        paragraph_editable.setAttribute('data-parent_id', internalSource[thisID]["parent"][0]);
        paragraph_editable.setAttribute('data-parent_component', internalSource[thisID]["parent"][1]);

        document.getElementById('actively_editing').insertAdjacentElement("afterbegin", paragraph_editable);

        editorLog("setting", $('#' + idOfEditText), "to have contents", internalSource[thisID]["content"]);

// from https://stackoverflow.com/questions/21257688/paste-rich-text-into-content-editable-div-and-only-keep-bold-and-italics-formatt

// figure out better how to do this as needed.
        $('[contenteditable]').on('paste',function(e) {
            e.preventDefault();
            var text = (e.originalEvent || e).clipboardData.getData('text/plain') || prompt('Paste something..');
            document.execCommand('insertText', false, text);
        });
        the_contents = internalSource[thisID]["content"]; 
        the_contents = expand_condensed_source_html(the_contents, "edit");
        the_contents = the_contents.replace(/\\cr/g, "<div><br></div>");
        $('#' + idOfEditText).html(the_contents);
        document.getElementById(idOfEditText).focus();
        editorLog("made edit box for", thisID);
        editorLog("which is", document.getElementById(idOfEditText));
        editorLog("Whth content CC" + document.getElementById(idOfEditText).innerHTML + "DD");
        editorLog("Whth content EE" + document.getElementById(idOfEditText).innerText + "FF");
        editorLog("Whth content GG" + document.getElementById(idOfEditText).textContent + "HH");
        this_char = "";
        prev_char = "";

      } else if (new_tag == "image") {
        var this_content_container = document.createElement('div');
        this_content_container.setAttribute('id', "actively_editing");
        this_content_container.setAttribute('data-age', oldornew);
        this_content_container.setAttribute('style', "width:50%; margin-left:auto; margin-right: auto; padding: 2em 3em 3em 3em; background: #fed");
        $("#" + thisID).replaceWith(this_content_container);

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

        document.getElementById(idOfEditText).focus();
        editorLog("made edit box for", thisID);
        editorLog("which is", document.getElementById(idOfEditText));
        editorLog("Whth content CC" + document.getElementById(idOfEditText).innerHTML + "DD");
        editorLog("Whth content EE" + document.getElementById(idOfEditText).innerText + "FF");
        editorLog("Whth content GG" + document.getElementById(idOfEditText).textContent + "HH");
        this_char = "";
        prev_char = "";

      } else {

        editorLog(new_tag, "create the object, then edit p in place", obj);

        var this_object = html_from_internal_id(new_id, "");
        var where_it_goes = document.getElementById(thisID);
        where_it_goes.insertAdjacentHTML('afterend', this_object[0]);
        where_it_goes.remove();
        var where_it_is = document.getElementById(thisID);
      

        editorLog("added this_object", this_object);
        editorLog("where it is", where_it_is);

        var this_source = internalSource[thisID];
        if (this_source.sourcetag == "sidebyside") {  // generalize to container was added
             editorLog("added an sbs", document.getElementById(thisID));
             editorLog("its .firstChild", document.getElementById(thisID).firstElementChild);
             editorLog("its .firstChild.firstchild", document.getElementById(thisID).firstElementChild.firstElementChild);
             var first_panel_id = document.getElementById(thisID).firstElementChild.firstElementChild.id;
             editorLog("first_panel_id", first_panel_id, document.getElementById(first_panel_id));
             make_current_editing_tree_from_id(first_panel_id);
             edit_menu_from_current_editing("entering");
        } else {
            var empty_p_child = $(where_it_is).find("p");
            if (empty_p_child[0]) {
                editorLog("found the empty p", empty_p_child);
                editorLog("found the empty p[0]", empty_p_child[0]);
                edit_in_place(empty_p_child[0], "new");
            } else {
                errorLog("error:  no empty p to edit")
            }
        }
      }

   } else {
        editorLog("Error: edit in place of object that is not already known", obj);
        editorLog("What is known:", internalSource)
     }
}

function resume_editing() {
    internalSource = previous_editing();
    replace_by_id(internalSource["root_data"]["id"], "html");
    edit_menu_for(top_level_id, "entering");
    console.log("editing resumed");
}

function replace_by_id(theid, format) {

    if (format != "html") { return "" }

    var this_object_new = output_from_id("",theid, format);

    console.log("id", theid);
// GO BACK AND REVISIT THE NEXT 3 LINES
//    document.getElementById(theid).setAttribute("id", "delete_me");
//    document.getElementById("delete_me").insertAdjacentHTML('beforebegin', this_object_new);
//    document.getElementById("delete_me").remove();

// need to also work with MJ3
//    MathJax.Hub.Queue(['Typeset', MathJax.Hub, document.getElementById(theid)]);
    console.log("MathJax on", theid, document.getElementById(theid));
//    MathJax.typesetPromise(document.getElementById(theid));
    MathJax.typesetPromise();

    console.log("adjusting workspace");
window.setTimeout(adjustWorkspace, 1000);
}

// temporary:  need to unify img and sbs layout
function modify_by_id(theid, modifier) {
    editorLog("modifying by id", theid);
    if (internalSource[theid]["sourcetag"] == "sbspanel") {
        modify_by_id_sbs(theid, modifier)
    } else if (environment_instances["project-like"].includes(internalSource[theid]["sourcetag"]) 
                || internalSource[theid]["sourcetag"] == "task") {
        modify_by_id_workspace(theid, modifier)
    } else {
        modify_by_id_image(theid, modifier)
    }
    save_edits()
}

function modify_by_id_workspace(theid, modifier) {

    var the_height = internalSource[theid]["workspace"];
    editorLog("the_height", the_height, "from", internalSource[theid]);

//modify: enlarge, shrink, enlargeslightly, shrinkslightly, done

    the_height = parseInt(the_height);
    editorLog('the_height, ', the_height);

    if (modifier == "enlarge") { the_height += 10 }
    else if (modifier == "shrink") { the_height -= 10 }
    else if (modifier == "enlargeslightly") { the_height += 1 }
    else if (modifier == "shrinkslightly") { the_height -= 1 }

    if (the_height < 0) { the_height = 0 }

    internalSource[theid]["workspace"] = the_height;
    editorLog("the_height is now", the_height);

    var this_workspace = document.getElementById(theid).querySelector(".workspace");
    this_workspace.setAttribute("style", "height:" + the_height*10 + "px");
    this_workspace.setAttribute("data-space", the_height);
}
 
function modify_by_id_image(theid, modifier) {

    var width = internalSource[theid]["width"];
    var marginleft = internalSource[theid]["marginleft"];
    var marginright = internalSource[theid]["marginright"];
    editorLog('width, , marginright, , marginleft', width, "mr", marginright, "ml",  marginleft);
    width = parseInt(width);
    marginright = parseInt(marginright);
    marginleft = parseInt(marginleft);

    var scale_direction = 1;
    var moving_direction = 1;
    if (modifier == "shrink") { scale_direction = -1 }
    else if (modifier == "left") { moving_direction = -1 }
    if ("enlarge shrink".includes(modifier)) {
        if ((width >= 100 && scale_direction == 1) || (width <= 0 && scale_direction == -1)) {
            editorLog("can't go above 100 or below 0");
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
            editorLog("already have no margins, width is", width);
        }
    } else if ("left right".includes(modifier)) {
        editorLog("marginleft*moving_direction", marginleft*moving_direction, "marginright*moving_direction", marginright*moving_direction);
        if ((marginleft > 0 && marginright > 0) || (marginright*moving_direction > 0) || (marginleft*moving_direction < 0)) {
            marginleft += moving_direction*move_scale;
            marginright += -1*moving_direction*move_scale;
        } else { 
            // do nothing:  this is a placeholder which is reached when both margins are 0
            // we choose to prioritize scale, so a 100% image cannot be shifted
            editorLog("already at 100%, width is", width);
        }
    }

    var the_new_sizes = "width: " + width + "%;";
    the_new_sizes += "margin-right: " + marginright + "%;";
    the_new_sizes += "margin-left: " + marginleft + "%;";

    internalSource[theid]["width"] = width;
    internalSource[theid]["marginleft"] = marginleft;
    internalSource[theid]["marginright"] = marginright;

    document.getElementById(theid).setAttribute("style", the_new_sizes);
}

function modify_by_id_sbs(theid, modifier) {

    var this_panel_source = internalSource[theid];
//    var this_width = this_panel_source["width"];
    var this_sbs_id = this_panel_source["parent"][0];
    var this_sbs_source = internalSource[this_sbs_id];
    editorLog("this_sbs_source", this_sbs_source);
    var marginleft = parseInt(this_sbs_source["marginleft"]);
    var marginright = parseInt(this_sbs_source["marginright"]);
    var these_siblings = this_sbs_source["content"];
    these_siblings = these_siblings.replace(/^\s*<&>\s*/, "");
    these_siblings = these_siblings.replace(/\s*<;>\s*$/, "");
    these_siblings = these_siblings.replace(/>\s*</g, "><");
    editorLog("these_siblings", these_siblings);
    var these_siblings_list = these_siblings.split("<;><&>");
    var this_panel_index = these_siblings_list.indexOf(theid);
    editorLog("this panel", theid, "is", this_panel_index, "within", these_siblings_list);
    var these_panel_widths = this_sbs_source.widths;
    var this_width = parseInt(these_panel_widths[this_panel_index]);
    var total_width = 0;
    editorLog("these html siblings",document.getElementById(these_siblings_list[0])," and ", document.getElementById(these_siblings_list[1]))
    editorLog("these siblings source",      internalSource[these_siblings_list[0]], "and",  internalSource[these_siblings_list[1]]);
    for(var j=0; j < these_siblings_list.length; ++j) {
    //    var t_wid = parseInt(internalSource[these_siblings_list[j]]["width"]);
        var t_wid = parseInt(these_panel_widths[j]);
        these_panel_widths[j] = t_wid;  // put it back as an integer
        editorLog("adding width", t_wid);
        total_width += t_wid;
 //       these_panel_widths.push(t_wid);
    }
//    if (this_width != these_panel_widths[this_panel_index]) {
//        errorLog("error: width", this_width, "not on list", these_panel_widths)
//    } else {
//        editorLog("width", this_width, "on list", these_panel_widths)
//    }

    editorLog("occ", marginleft, "u", total_width, "pi", marginright, "total", marginleft + total_width + marginright, "ratio", marginright/total_width)
    var remaining_space = 100 - (marginleft + total_width + marginright);
    editorLog("remaining_space", remaining_space);

//modify: enlarge, shrink, left, right, ??? done

// make the data structure better, then delete this comment
// currently style looks like "width: 66%; margin-right: 17%; margin-left: 17%"
    editorLog('width', this_width, "mr", marginright, "ml",  marginleft);

    editorLog("modifier", modifier);

    var scale_direction = 1;
    var moving_direction = 1;

    if (modifier == "enlargeall") {
        editorLog("enlarging all", "remaining space", remaining_space);
        if (remaining_space >= these_panel_widths.length) {
            for (var j=0; j < these_panel_widths.length; ++j) {
                these_panel_widths[j] += 1
            }
   // probablu the next case handles the first case
        } else if (remaining_space + marginleft + marginright >= these_panel_widths.length) {
            for (var j=0; j < these_panel_widths.length; ++j) {
                these_panel_widths[j] += 1
            }
            var missing_length = these_panel_widths.length - remaining_space;
            while (missing_length) {
                missing_length -= 1;
                if (missing_length % 2) {
                    if (marginleft) { marginleft -= 1 }
                    else { marginright -= 1 }
                } else {
                    if (marginright) { marginright -= 1 }
                    else { marginleft -= 1 }
                }
            }
        } else {
            editorLog("Problem: not implemented yet")
        }
    } else if (modifier == "shrinkall") {
        for (var j=0; j < these_panel_widths.length; ++j) {
            if (these_panel_widths[j]) { these_panel_widths[j] -= 1 }
        }
    } else if (modifier == "enlarge") {
        editorLog("enlarging one");
        if (remaining_space) { these_panel_widths[this_panel_index] += 1 }
    } else if (modifier == "shrink") {
        editorLog("shrinking one");
        if (these_panel_widths[this_panel_index]) { these_panel_widths[this_panel_index] -= 1 }
    } else if (modifier == "leftplus") {
        if (remaining_space) { marginleft += 1 }
    } else if (modifier == "leftminus") {
        if (marginleft) { marginleft -= 1 }
    } else if (modifier == "rightplus") {
        if (remaining_space) { marginright += 1 }
    } else if (modifier == "rightminus") { 
        if (marginright) { marginright -= 1 }
    }
    editorLog("now these_panel_widths", these_panel_widths);

// missing cases??

    internalSource[this_sbs_id]["marginleft"] = marginleft;
    internalSource[this_sbs_id]["marginright"] = marginright;
    internalSource[this_sbs_id]["widths"] = these_panel_widths;

// next is wrong, becuase the sbsrow does not have an id
/*
    document.getElementById(this_sbs_id).style.marginLeft = marginleft + "%";
    document.getElementById(this_sbs_id).style.marginRight = marginright + "%";
*/
    document.getElementById(theid).parentElement.style.marginLeft = marginleft + "%";
    document.getElementById(theid).parentElement.style.marginRight = marginright + "%";

    for (var j=0; j < these_siblings_list.length; ++j) {
        var this_id = these_siblings_list[j];
//        internalSource[this_id]["width"] = these_panel_widths[j];
        var width = rescale(these_panel_widths[j], 100, marginleft, marginright)
  //      document.getElementById(this_id).style.width = these_panel_widths[j] + "%";
        document.getElementById(this_id).style.width = width + "%";
    }
    editorLog("NOW these html siblings",document.getElementById(these_siblings_list[0])," and ", document.getElementById(these_siblings_list[1]))
    editorLog("NOW these siblings source",      internalSource[these_siblings_list[0]], "and",  internalSource[these_siblings_list[1]]);
    editorLog("and internalSource[this_id]", internalSource[this_id]);
    editorLog("and also internalSource[this_sbs_id]", internalSource[this_sbs_id]);
}

function move_by_id_local(theid, thehandleid) {
    // when moving an object within a page, we create a phantomobject that is manipulated
    // the actual movement is handled by move_object(e)

    first_move = true;

    document.getElementById("edit_menu_holder").remove()
    document.getElementById(theid).classList.remove("may_select");

    moved_content = internalSource[theid];
    moved_content_tag = moved_content["sourcetag"];
    ongoing_editing_actions.push(["moved", moved_content_tag, theid]);
    moved_parent_and_location = moved_content["parent"];
    editorLog("moving", theid);
    editorLog("moved_parent_and_location", moved_parent_and_location);
  // code duplicated elsewhere
    var where_it_was = internalSource[moved_parent_and_location[0]][ moved_parent_and_location[1] ];
    editorLog("where_it_was", where_it_was);
    var object_in_parent = '<&>' + theid + '<;>';
    var where_it_is = where_it_was.replace(object_in_parent, "");
    editorLog("where_it_is ZZ" + where_it_is + "EE");
    internalSource[moved_parent_and_location[0]][ moved_parent_and_location[1] ] = where_it_is;

    // but first, remember the initial location of the object

    moving_object = document.getElementById(theid);
    editorLog("moving", moving_object, "within this page");
    editorLog("moving_id", theid);
    editorLog("current_editing[tree][0]", current_editing["tree"][0]);
    if (moved_content_tag == "li") {
        movement_location_neighbors = next_editable_of(current_editing["tree"][0][0], "li-only");
    } else if (tag_type(moved_content_tag) == "p") {
        movement_location_neighbors = next_editable_of(current_editing["tree"][0][0], "inner-block");
    } else {
        movement_location_neighbors = next_editable_of(current_editing["tree"][0][0], "outer-block");
    }
    editorLog("movement_location_neighbors", movement_location_neighbors);
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

    if (!foundit) { errorLog("serious error:  trying to move an object that is not movable", theid) }

    editorLog("movement_location_tmp", movement_location_tmp);
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
    editorLog("movement_location_ct", movement_location_ct);
    editorLog("movement_location", movement_location);

    editorLog("made", movement_location_options.length, "movement_location_options", movement_location_options);
    editorLog("from", movement_location_neighbors.length, "movement_location_neighbors", movement_location_neighbors);
 
    var the_phantomobject = document.createElement('div');
    the_phantomobject.setAttribute("id", "phantomobject");
    the_phantomobject.setAttribute("data-moving_id", theid);
    the_phantomobject.setAttribute("data-handle_id", thehandleid);
    the_phantomobject.setAttribute("class", "phantomobject move");
    the_phantomobject.setAttribute("tabindex", "-1");
    var these_instructions = '<div class="movearrow"><span class="arrow">&uarr;</span><p class="up">"shift-tab", or "up arrow", to move up</p></div>';
    these_instructions += '<div class="movearrow"><p class="done">"return" or "escape" to set in place </p></div>';
    these_instructions += '<div class="movearrow"><span class="arrow">&darr;</span><p class="down">"tab" or "down arrow" to move down</p></div>';
    the_phantomobject.innerHTML = these_instructions;
    //  if we are moving a p which has parent li, and it is the only p there, then delete the parent li
    //  note:  this will be wrong if there is other non-p siblings inside the li
    var moving_object_replace = moving_object;
    if (tag_type(moved_content_tag) == "p" && internalSource[moved_parent_and_location[0]]["sourcetag"] == "li") {
        // check if that p is the only thing inside the li (so the li is empty when we move the p), and if so,
        // remove that li from internalSource and also the HTML, and the reverence to it in internalSource
        if (moving_object.parentElement.getElementsByTagName("p").length == 1) {
            moving_object_replace = moving_object.parentElement
            var now_empty_li_id = moved_parent_and_location[0];
            editorLog("list item now empty:", now_empty_li_id);
            var now_empty_li_parent_and_location = internalSource[now_empty_li_id]["parent"];
            var where_it_was = internalSource[now_empty_li_parent_and_location[0]][ now_empty_li_parent_and_location[1] ];
            var object_in_parent = '<&>' + now_empty_li_id + '<;>';
            var where_it_is = where_it_was.replace(object_in_parent, "");
            delete internalSource[now_empty_li_id];
            editorLog("where_it_is II" + where_it_is + "OO");
            internalSource[now_empty_li_parent_and_location[0]][ now_empty_li_parent_and_location[1] ] = where_it_is;
        }
    }
    moving_object_replace.replaceWith(the_phantomobject)
    document.getElementById("phantomobject").focus();
}

function move_object(e) {
                // we have alread set movement_location_options and movement_location
    editorLog("movement_location",movement_location);
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
        if (first_move) { first_move = false; editorLog("did first move") }
        if (movement_location == movement_location_options.length - 1) {
            alert("can't move past the bottom")
        } else {
            movement_location += 1
        }
    } else if (e.code == "Escape" || e.code == "Enter" || e.code == "ArrowRight") {
        e.preventDefault();
        editorLog(" decided where to put moving_object", moving_object);
        var id_of_moving_object = document.getElementById('phantomobject').getAttribute("data-moving_id");
        editorLog("moving object started as", internalSource[id_of_moving_object]);
        var handle_of_moving_object = document.getElementById('phantomobject').getAttribute("data-handle_id");
        document.getElementById('phantomobject').remove();
        var new_anchor_and_position = movement_location_options[movement_location]
        editorLog("new_location_anchor",new_anchor_and_position);
        new_anchor_and_position[0].insertAdjacentElement(new_anchor_and_position[1], moving_object);

        // the html appears to be updated, but we still need to update both the internal source:
        var new_neighbor_id = new_anchor_and_position[0].id;
        editorLog("new_neighbor_id", new_neighbor_id);
        editorLog("which has source", internalSource[new_neighbor_id]);
        var new_neighbor_rel_pos = new_anchor_and_position[1];
        var [new_neighbor_parent, new_neighbor_location] = internalSource[new_neighbor_id]["parent"];
        var new_neighbor_in_context = internalSource[new_neighbor_parent][new_neighbor_location];
        editorLog("new_neighbor_in_context was", new_neighbor_in_context);
        var neighbor_tag = '<&>' + new_neighbor_id + '<;>';
        var neighbor_tag_re = new RegExp(neighbor_tag);

        var moving_object_tag = '<&>' + id_of_moving_object + '<;>';
        if (new_neighbor_rel_pos == "beforebegin") {
       //     new_neighbor_in_context.replace(neighbor_tag, moving_object_tag + "\n" + neighbor_tag)
//  RegExp
            new_neighbor_in_context = new_neighbor_in_context.replace(neighbor_tag_re, moving_object_tag + "\n" + neighbor_tag)
        } else {
            new_neighbor_in_context = new_neighbor_in_context.replace(neighbor_tag_re, neighbor_tag + "\n" + moving_object_tag)
        }
        editorLog("new_neighbor_in_context is", new_neighbor_in_context);
        internalSource[new_neighbor_parent][new_neighbor_location] = new_neighbor_in_context;
        internalSource[id_of_moving_object]["parent"] = [new_neighbor_parent, new_neighbor_location];
        editorLog("moving object ended as", internalSource[id_of_moving_object]);

        save_edits();

        // and the navigation information
        make_current_editing_tree_from_id(handle_of_moving_object);

        var most_recent_edit = ongoing_editing_actions.pop();
        recent_editing_actions.unshift(most_recent_edit);

        edit_menu_from_current_editing("entering");
        return

    } else {
        editorLog("don't know how to move with", e.code)
    }

    editorLog("now movement_location", movement_location);
    var the_phantomobject = document.getElementById('phantomobject');
    movement_location_options[movement_location][0].insertAdjacentElement(movement_location_options[movement_location][1], the_phantomobject);
    document.getElementById("phantomobject").focus();
}

function delete_by_id(theid, thereason) {
    // reasons to delete something:  author wants it deleted, it is empty, ...
        // first delete the specific object
    final_added_object = "";
    editorLog("deleting by theid", theid, "with content", internalSource[theid]);
    var deleted_content = internalSource[theid];
    var parent_and_location = deleted_content["parent"];
    delete internalSource[theid];
    editorLog("deleted", theid, "so", theid in internalSource, "now", internalSource);
        // and save what was deleted
    if (theid in old_content) {
        old_content[theid].push(deleted_content)
    } else {
        old_content[theid] = [deleted_content]
    }
    if (thereason != "newempty") {  // not sure newempty can still happen
        ongoing_editing_actions.push(["deleted ", deleted_content["sourcetag"], theid]);
    }
        // update the parent of the object
    var current_level = current_editing["level"];
    var where_it_was = internalSource[parent_and_location[0]][ parent_and_location[1] ];
    var object_in_parent = '<&>' + theid + '<;>';
    var where_it_is = where_it_was.replace(object_in_parent, "");
    editorLog("where_it_is ZZ" + where_it_is + "EE");
    internalSource[parent_and_location[0]][ parent_and_location[1] ] = where_it_is;
        // if the parent is empty, delete it
    if (!(where_it_is.trim()) && (parent_and_location[1] == "content" || parent_and_location[1] == "statement")) {
        editorLog("      deleted from within", internalSource[parent_and_location[0]]);
        document.getElementById(theid).removeAttribute("data-editable");  // so it is invisible to next-editable-of as we delete its parent
        if (internalSource[parent_and_location[0]][ "sourcetag" ] == "li") {
            editorLog("not going up a level, because it is a list element")
        } else {
            current_editing["level"] -= 1;
        }
        delete_by_id(parent_and_location[0], thereason)
    } else {  // else, because the parent is going to be deleted, so no need to delete the child
        // delete from the html
        var current_index = current_editing["location"][current_level] + 1;  // +1 because the deleted item is still in the current_editing tree
        if (thereason == "empty" || thereason == "newempty") {
            editorLog("removing from DOM", document.getElementById(theid));
            document.getElementById(theid).remove();
            current_index -= 1;
            editorLog("current_index", current_index, "current_level", current_level);
            editorLog(current_editing["tree"][ current_level ]);
                // hack because adding a list (inside a defn?) is not updating the tree properly
            if (current_index > current_editing["tree"][ current_level ].length - 1) {
                current_index = current_editing["tree"][ current_level ].length - 1
            }
            if (current_editing["tree"][ current_level ][ current_index ].id == theid) {
                current_editing["tree"][ current_level ].splice(current_index, 1)
            }
            editorLog("empty or newempty", thereason)
        } else {
            editorLog("deleting for another reason", thereason)
            document.getElementById("edit_menu_holder").remove()
            document.getElementById(theid).setAttribute("id", "deleting");
            document.getElementById("deleting").removeAttribute("data-editable");  // so it is invisible to next-editable-of
            setTimeout(() => {  document.getElementById("deleting").remove(); }, 600);
        }

        if (current_index >= current_editing["tree"][ current_level ].length) {
            current_index = current_editing["tree"][ current_level ].length - 2;
        }
        editorLog("current_index", current_index, "in", current_editing["tree"][ current_level ]);
        editorLog("object of interest", current_editing["tree"][ current_level ][ current_index ]);
        editorLog("current_level", current_level, "on", current_editing["tree"]);
        make_current_editing_tree_from_id(current_editing["tree"][ current_level ][ current_index].id);
        edit_menu_from_current_editing("entering");
    }
    save_edits()
}


var internalSource = {  // currently the key is the HTML id
   "root_data": {"id": "page-1", "number_base": "0.1" }
}

/* top_level_id is a mistake:  just use internalSource.root_data.id */
var top_level_id = internalSource["root_data"]["id"];

var current_editing = {
    "level": 0,
    "location": [0],
    "tree": [ [document.getElementById(top_level_id)] ]
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
            enter_option.setAttribute('class', 'edit_menu');

            enter_option.innerHTML = menu_options_for(this_obj_id, "XunusedX", "base");

            document.getElementById("local_menu_holder").insertAdjacentElement("afterbegin", enter_option);

}

function extract_internal_contents(some_text) {

    // some_text must be a paragraph with mixed content only contining
    // non-nested tags
    the_text = some_text;
    editorLog("            xxxxxxxxxx  the_text is", the_text);
    editorLog("extract_internal_contents");

    // delete class information
    the_text = the_text.replace(/ class="[^"]"/g, "");

    // inline from previous editing
    editorLog("extracting where 'data-editable...'");
    the_text = the_text.replace(/<([^<]+) data-editable="[^"]+" tabindex="-1">(.*?)<[^<]+>/g, save_internal_cont);
    editorLog("extracting where 'contenteditable...'");
    the_text = the_text.replace(/<([^<]+) contenteditable="false">(.*?)<[^<]+>/g, save_internal_cont);
    // new $math$
    editorLog("extracting new $math$");
    the_text = the_text.replace(/(^|\s)\$([^\$]+)\$(\s|$|[.,!?;:])/mg, extract_new_math);
    // new \\(math\\)
    editorLog("extracting new \\(math\\)");
    the_text = the_text.replace(/(^|.)\\\(([^\$]+)\\\)(.|$)/g, extract_new_math);
    // new <m>math</m>
    editorLog("extracting new <m>math</m>");
    the_text = the_text.replace(/(^|.)&lt;m&gt;(.*?)&lt;\/m&gt;(.|$)/g, extract_new_math);

    // "..." to <ellipsis/>, which will then be processed
    the_text = the_text.replace(/\.\.\./g, '&lt;ellipsis\/&gt;');
    // same for etc
    the_text = the_text.replace(/(\s)etc\.?([^a-zA-Z])/g, '$1&lt;etc\/&gt;$2');

    for (var j=0; j < inline_abbrev.length; ++j) {
        var this_tag = inline_abbrev[j];
        editorLog("this_tag", this_tag);
        var this_tag_search = "&lt;(" + this_tag + ")\\/&gt;";
        editorLog("searching for", this_tag_search);
        var this_tag_search_re = new RegExp(this_tag_search,"g");
        the_text = the_text.replace(this_tag_search_re, extract_new_inline)
    }

    // "quote" to <q>quote</q>, which will then be processed
    the_text = the_text.replace(/(^|\s)"([^"]+)"(\s|$|[.,!?;:])/g, '$1&lt;q&gt;$2&lt;\/q&gt;$3');
    the_text = the_text.replace(/(^|\s)“([^”]+)”(\s|$|[.,!?;:])/g, '$1&lt;q&gt;$2&lt;\/q&gt;$3');
    the_text = the_text.replace(/(^|\s)‘([^’]+)’(\s|$|[.,!?;:])/g, '$1&lt;q&gt;$2&lt;\/q&gt;$3');

    for (var j=0; j < inline_tags.length; ++j) {
        var this_tag = inline_tags[j];
        editorLog("this_tag", this_tag);
        var this_tag_search = "&lt;(" + this_tag + ") *&gt;" + "(.*?)" + "&lt;\\/" + this_tag + "&gt;";
        editorLog("searching for", this_tag_search);
        var this_tag_search_re = new RegExp(this_tag_search,"g");
        the_text = the_text.replace(this_tag_search_re, extract_new_inline)
    }

    return the_text
}

function extract_new_math(match, sp_before, math_content, sp_after) {
    var new_math_id = randomstring();
    internalSource[new_math_id] = { "xml:id": new_math_id, "sourcetag": "m",
                          "content": math_content}
    return sp_before + "<&>" + new_math_id + "<;>" + sp_after
}
function extract_new_inline(match, the_tag, the_content) {
    var new_id = randomstring();
    editorLog("extracting", the_content, "inside", the_tag);
    internalSource[new_id] = { "xml:id": new_id, "sourcetag": the_tag,
                          "content": the_content};
    return "<&>" + new_id + "<;>"
}
function extract_new_abbrev(match, the_tag) {
    var new_id = randomstring();
    editorLog("extracting", the_content, "inside", the_tag);
    internalSource[new_id] = { "xml:id": new_id, "sourcetag": the_tag};
    return "<&>" + new_id + "<;>"
}

// rename this next function
function save_internal_cont(match, contains_id, the_contents) {
    this_id = contains_id.replace(/.*id="(.+?)".*/, '$1');

    editorLog("id", this_id, "now has contents", the_contents);
    if ("content" in internalSource[this_id]) {   // not all objects have content
        internalSource[this_id]["content"] = the_contents;
    } else if (internalSource[this_id]["sourcetag"] == "xref") {
        // this needs work once we have  text="custom"  references
        internalSource[this_id]["ref"] = the_contents;
    }
    editorLog("all of it is now", internalSource[this_id]);
    return "<&>" + this_id + "<;>"
}
function assemble_internal_version_changes(object_being_edited) {
    editorLog("in assemble_internal_version_changes");
    editorLog("current active element to be saved", object_being_edited);
    editorLog("which has parent", object_being_edited.parentElement);
    editorLog("whose age is", object_being_edited.parentElement.getAttribute("data-age"));

    var oldornew = object_being_edited.parentElement.getAttribute("data-age");
    if (!oldornew) { oldornew = object_being_edited.getAttribute("data-age") }
    editorLog("    OLDorNEW", oldornew);

    var possibly_changed_ids_and_entry = [];
    var nature_of_the_change = "";

//    var object_being_edited = document.activeElement;
    var location_of_change = object_being_edited.parentElement;
    var this_arrangement_of_objects = "";

    if (object_being_edited.classList.contains("paragraph_input")) {
        editorLog("found paragraph_input");
        nature_of_the_change = "replace";
        var paragraph_content = object_being_edited.innerHTML;
    //    editorLog("paragraph_content from innerHTML", paragraph_content);
        paragraph_content = paragraph_content.trim();

        var cursor_location = object_being_edited.selectionStart;

        editorLog("cursor_location", cursor_location, "out of", paragraph_content.length, "paragraph_content", paragraph_content);

        var parent_and_location = [object_being_edited.getAttribute("data-parent_id"), object_being_edited.getAttribute("data-parent_component")];
        editorLog("parent_and_location", parent_and_location);
        editorLog("of ", object_being_edited);

        var prev_id = object_being_edited.getAttribute("data-source_id");
        editorLog("prev_id", prev_id);
        editorLog("which contains", internalSource[prev_id]);

        // need to replace the below by split_paragraphs

        // does the textbox contain more than one paragraph?
        var paragraph_content_list = paragraph_content.split("<div><br></div>");
        editorLog("there were", paragraph_content_list.length, "paragraphs, but some may be empty");
        for (var j=0; j < paragraph_content_list.length; ++j) {
            editorLog("paragraph", j, "begins", paragraph_content_list[j].substring(0,20))
        }

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
            if (!this_paragraph_contents_raw) { editorLog("empty paragraph") }
            else { paragraph_content_list_trimmed.push(this_paragraph_contents_raw) }
       //     editorLog("this_paragraph_contents_raw", this_paragraph_contents_raw);
            editorLog("done transforming paragraph", j, "with object_being_edited",object_being_edited);
            editorLog("which has contents", this_paragraph_contents_raw)
        }

        if (!paragraph_content_list_trimmed.length ) { 
                // empty, so insert it and delete it later
            paragraph_content_list_trimmed = [""];
        }

        for (var j=0; j < paragraph_content_list_trimmed.length; ++j) {
            editorLog("_trimmed paragraph", j, "begins", paragraph_content_list_trimmed[j].substring(0,20))
        }
        for (var j=0; j < paragraph_content_list_trimmed.length; ++j) {
            var this_paragraph_contents = paragraph_content_list_trimmed[j];
            editorLog("this_paragraph_contents", this_paragraph_contents.substring(0,20));
            if (j == 0 && prev_id) {
                if (prev_id in internalSource) {
                    // the content is referenced, so we update the referenced content
                       // need to check internal content, such as em or math
                    this_paragraph_contents = extract_internal_contents(this_paragraph_contents);
                    if (internalSource[prev_id]["content"] != this_paragraph_contents) {
                        if (internalSource[prev_id]["content"]) {
                            ongoing_editing_actions.push(["changed", "p", prev_id]);
                        } else if (this_paragraph_contents) {
                            ongoing_editing_actions.push(["new", "p", prev_id]);
                        }
                        internalSource[prev_id]["content"] = this_paragraph_contents;
                        editorLog("changed content of", prev_id)
                    } else if (!this_paragraph_contents) {  // adding an empty paragraph
                        ongoing_editing_actions.push(["empty", "p", prev_id]);
                    } else {
                        // this means the contents are nonempty and unchanged, so don't record is as a change
                    }
                    possibly_changed_ids_and_entry.push([prev_id, "content", oldornew]);
                    this_arrangement_of_objects = internalSource[parent_and_location[0]][parent_and_location[1]];
                } else {
                    errorLog("error:  existing tag from input", prev_id, "not in internalSource")
                }
            } else {  // a newly created paragraph
                var this_object_internal = {"sourcetag": "p", "title": ""}; //p don't have title
                this_object_label = randomstring();
                this_object_internal["xml:id"] = this_object_label;
                this_object_internal["parent"] = parent_and_location;

                // put the new p after the previous p in the string describing the neighboring contents
                var object_before = new RegExp('(<&>' + prev_id + '<;>)');
                this_arrangement_of_objects = this_arrangement_of_objects.replace(object_before, '$1' + '\n<&>' + this_object_label + '<;>');
                prev_id = this_object_label;
                
                this_paragraph_contents = extract_internal_contents(this_paragraph_contents);
                this_object_internal["content"] = this_paragraph_contents;
                internalSource[this_object_label] = this_object_internal
                editorLog("just inserted at label", this_object_label, "content starting", this_paragraph_contents.substring(0,11), "which is now", internalSource[this_object_label]);
                ongoing_editing_actions.push(["added", "p", this_object_label]);
// here is where we can record that somethign is empty, hence should be deleted
                possibly_changed_ids_and_entry.push([this_object_label, "content", "new"]);
            }
          }
          editorLog("parent_and_location", parent_and_location);
          editorLog("this_arrangement_of_objects was",  internalSource[parent_and_location[0]][parent_and_location[1]]);
          internalSource[parent_and_location[0]][parent_and_location[1]] = this_arrangement_of_objects;
          editorLog("this_arrangement_of_objects is", this_arrangement_of_objects);
    } else if (object_being_edited.classList.contains("displaymath_input")) {
       editorLog("found displaymath_input");
        nature_of_the_change = "replace";
        var paragraph_content = object_being_edited.innerHTML;
    //    editorLog("paragraph_content from innerHTML", paragraph_content);
        paragraph_content = paragraph_content.trim();

        var cursor_location = object_being_edited.selectionStart;

        editorLog("cursor_location", cursor_location, "out of", paragraph_content.length, "paragraph_content", paragraph_content);

        var parent_and_location = [object_being_edited.getAttribute("data-parent_id"), object_being_edited.getAttribute("data-parent_component")];

        editorLog("parent_and_location", parent_and_location);
        editorLog("of ", object_being_edited);

        var prev_id = object_being_edited.getAttribute("data-source_id");
        editorLog("prev_id", prev_id);
        editorLog("which contains", internalSource[prev_id]);

        // textbox may contain more than one paragraph
        var paragraph_content_list = split_paragraphs(paragraph_content);
        var this_paragraph_contents = paragraph_content_list.join("\n\\cr\n");
        this_paragraph_contents = extract_internal_contents(this_paragraph_contents);
         
        if (!internalSource[prev_id]["content"]) {
            ongoing_editing_actions.push(["new", "md", prev_id]);
        } else {
            ongoing_editing_actions.push(["changed", "md", prev_id]);
        }

        internalSource[prev_id]["content"] = this_paragraph_contents
        possibly_changed_ids_and_entry.push([prev_id, "content", oldornew]);

    } else if (object_being_edited.getAttribute('data-component') == "title" ||
               object_being_edited.getAttribute('data-component') == "caption") {

        var this_content_type = object_being_edited.getAttribute('data-component');
        nature_of_the_change = "replace";
        var line_being_edited = object_being_edited;
        var line_content = line_being_edited.innerHTML;
        line_content = line_content.trim();
        editorLog("the content (is it a title or caption?) is", line_content);
        var owner_of_change = object_being_edited.getAttribute("data-source_id");
        var component_being_changed = object_being_edited.getAttribute("data-component");
        editorLog("component_being_changed", component_being_changed, "within", owner_of_change);
        if (internalSource[owner_of_change][component_being_changed]) {
            ongoing_editing_actions.push(["changed", this_content_type, owner_of_change]);
        } else {
            ongoing_editing_actions.push(["added", this_content_type, owner_of_change]);
        }
        // update the title of the object
        internalSource[owner_of_change][component_being_changed] = line_content;
        possibly_changed_ids_and_entry.push([owner_of_change, this_content_type]);

    } else if (object_being_edited.classList.contains("image_source")) {
        // currently this only handles images by URL.
        // later do the case of uploading an image.
        var image_src = object_being_edited.innerHTML;

        // what is the right way to do this?
        image_src = image_src.replace(/<div>/g, "");
        image_src = image_src.replace(/<\/div>/g, "");
        image_src = image_src.trim();
        editorLog("changing image src to", image_src);

        var image_being_changed = object_being_edited.getAttribute("data-source_id");
        editorLog("image_being_changed ", image_being_changed);

        if (internalSource[image_being_changed]["source"]) {
            ongoing_editing_actions.push(["changed", "source", image_being_changed]);
        } else {
            ongoing_editing_actions.push(["added", "source", image_being_changed]);
        }
        internalSource[image_being_changed]["source"] = image_src;
        editorLog("image being changed is", internalSource[image_being_changed]);
    //    possibly_changed_ids_and_entry.push([owner_of_change, "image"]);
        possibly_changed_ids_and_entry.push([image_being_changed, "image"]);


    } else if (inline_tags.includes(object_being_edited.tagName.toLowerCase())) {
        editorLog(object_being_edited, "is inline, so processing parent");
        return assemble_internal_version_changes(object_being_edited.parentElement)
    } else if (object_being_edited.classList.contains("edit_math_row")) {
        nature_of_the_change = "replace";
        var line_being_edited = object_being_edited;
        var line_content = line_being_edited.innerHTML;
        line_content = line_content.trim();
        editorLog("the content (is it a title?) is", line_content);
        var owner_of_change = object_being_edited.getAttribute("id");
    //    var component_being_changed = object_being_edited.getAttribute("data-component");
        var component_being_changed = "content";
        editorLog("component_being_changed", component_being_changed, "within", owner_of_change);
        // update the title of the object
        if (internalSource[owner_of_change][component_being_changed]) {
            ongoing_editing_actions.push(["changed", "mrow", owner_of_change]);
        } else {
            ongoing_editing_actions.push(["added", "mrow", owner_of_change]);
        }
        internalSource[owner_of_change][component_being_changed] = line_content;
        possibly_changed_ids_and_entry.push([owner_of_change, "mrow"]);

    } else {
        errorLog("trouble editing", object_being_edited, "AAA", object_being_edited.tagName.toLowerCase(), "not in", inline_tags);
        alert("don;t know how to assemble internal_version_changes of " + object_being_edited.tagName)
    }
    editorLog("finished assembling internal version, which is now:",internalSource);
    editorLog("    NUMBER of things chagnged:", possibly_changed_ids_and_entry.length);
    return [nature_of_the_change, location_of_change, possibly_changed_ids_and_entry]
}

function wrap_tag(tag, content, attribute_values) {
    // tag is either an XML tag name, or [opening_tag, closing_tag]

    // layout: inline or block or title
    // is this the right place to handle empty content?
//    editorLog("calling wrap_tag", "tag", tag, "content", content, "attribute_values", attribute_values);
    if (!content && !tag) { return "" }
    if (!content && !always_empty_tags.includes(tag) && !allowed_empty_tags.includes(tag)) { return "" }
    if (!tag) { return content }

    var opening_tag = closing_tag = "";

    if (typeof tag == "string") {
      if (tag) {
        opening_tag = "<" + tag;
        for (var j=0; j < attribute_values.length; ++j) {
            opening_tag += ' ' + attribute_values[j]
        }
        closing_tag = "</" + tag + ">";
      }
      if (!content && (always_empty_tags.includes(tag) || allowed_empty_tags.includes(tag))) {
        opening_tag += "/>";
        closing_tag = "";
      } else {
        opening_tag += ">";
      }

      if (tag_display["inline"].includes(tag)) {
        // do nothing
      } else if (tag_display["title"].includes(tag)) {
        opening_tag = "\n" + opening_tag;
        closing_tag = closing_tag + "\n"
      } else if (tag_display["block-tight"].includes(tag)) {
        // do nothing
      } else {  //the default
        opening_tag = "\n" + opening_tag + "\n";
        if (closing_tag) {
            closing_tag = "\n" + closing_tag + "\n"
        }
      }
    } else if (tag) {
        [opening_tag, closing_tag] = tag
        for (var j=0; j < attribute_values.length; ++j) {
            opening_tag += ' ' + attribute_values[j]
        }
    } else {
        opening_tag = "";
        closing_tag = "";
    }
    if (!opening_tag) { opening_tag = "" }
    if (!closing_tag) { closing_tag = "" }

    if (content.includes("N.m")) { editorLog("3 ----- content",content); editorLog("opening_tag", opening_tag) }

    if (opening_tag.startsWith("<p") && !content) {
        alert("empty p")
    }

    return opening_tag + content.trim() + closing_tag
}

function output_from_source(the_object, output_structure, format) {

    if (!the_object) { return ""}
    if (!output_structure) { return "MISSING STRUCTURE"}

    editorLog("calling output from_source", "the_object", the_object, "output_structure", output_structure, "format", format);
    // format: html, pretext (or source?)
    var the_answer = "";
    var output_tag = output_structure.tag;
    if (!output_tag) {
        output_tag = [output_structure.tag_opening, output_structure.tag_closing]
    }

    var output_attributes = [];
    if ("attributes" in output_structure && output_structure.attributes) {
        output_attributes = output_structure.attributes;
    } else {
        output_attributes = []
    }
    var output_attributes_values = [];
    for (var j=0; j < output_attributes.length; ++j) {
        var attr_name = output_attributes[j];
 //       var attr_val = the_object[attr_name];
        var attr_val = attr_name;
        editorLog("attr_val", attr_val);
        attr_val = attr_val.replace(/<&>(.*?)<;>/g, function (match, newid) { 
               if (newid.startsWith("{")) {
                   newid = newid.slice(1,-1);
                   if (newid in output_structure) {
                       return output_structure[newid]
                   } else {  // don't want to return 'undefined'
                       return ""
                   }
               } else if (newid.startsWith("(")) {
                   var this_piece = newid.slice(1,-1);
                   var this_fcn;
                   [this_fcn, this_piece] = this_piece.split(",");
                   return process_value_from_source(this_fcn, this_piece, the_object)
               } else {
                   if (newid in the_object) {
                       return the_object[newid]
                   } else {
                       return ""
                   }
               }
             });
        editorLog("         attr_val", attr_val);
        if (attr_val && !attr_val.includes('""')) {
            output_attributes_values.push(attr_val)
        }
    }

    editorLog("output_structure", output_tag, "is", output_structure);
    editorLog("output_attributes_values", output_attributes_values);
    editorLog("output_structure.pieces", output_structure.pieces);
    for (var j=0; j < output_structure.pieces.length; ++j) {
        var this_piece_output = "";
        var [this_piece, this_tag] = output_structure.pieces[j];
        editorLog("output_structure", output_structure);
            // when this_piece is provisional, then this_tag is actually the key for the required content
        editorLog(j, "this_piece", this_piece, "this_tag", this_tag, "output_tag", output_tag);
        if (this_piece.startsWith("{")) {
            this_piece = this_piece.slice(1,-1);
            this_piece_output += output_from_source(the_object, objectStructure[this_piece][format], format);
            editorLog("wrapping in bracketed tag", this_tag);
            the_answer += wrap_tag(this_tag, this_piece_output, [])
        } else if (this_piece.startsWith("%")) {
     // need to distinguish between the case where this object exists,
     // and when it does not exist and we want a placeholder
            this_piece = this_piece.slice(1,-1);
            editorLog("% % % % % % % % % ", this_piece, "this_tag", this_tag, "the_object",  the_object);
            editorLog("% % % % % % % % % ", the_object[this_piece]);
            editorLog("% % % % % % % % % ", the_object[this_tag]);
            if (the_object[this_tag]) {
 //               var sub_object = {};

//                Object.assign(sub_object, the_object);

  //              sub_object['type-contained'] = this_tag;
  //              editorLog("sub_object", sub_object);
         //       this_piece_output = output_from_source(sub_object, objectStructure[this_piece][format], format);
                this_piece_output = expand_condensed_source_html(the_object[this_tag],"html?");
    //            this_piece_output = output_from_source(sub_object, objectStructure[this_piece][format], format);
                the_answer += this_piece_output;
                editorLog("this piece exists", this_piece, "this_piece_output", this_piece_output)
            } else {
                editorLog("making placeholder for", this_piece);
                the_answer += wrap_tag("div", "", ['class="placeholder ' + this_piece + '"', 'data-parent_id="' + the_object['xml:id'] + '"', 'data-has="' + this_piece + '"', 'tabindex="-1"', 'data-editable="123456"', 'data-placeholder=""'])
            }
        } else if (this_piece.startsWith("(")) {
            editorLog("whole this_piece", this_piece);
            this_piece = this_piece.slice(1,-1);
            var this_fcn;
            [this_fcn, this_piece] = this_piece.split(",");
            var this_content = process_value_from_source(this_fcn, this_piece, the_object)
            editorLog(j, "parenthesized content", this_content, "this_piece", this_piece, "XX", this_tag)
            the_answer += wrap_tag(this_tag, this_content, [])
        } else if (this_piece in the_object) {
            this_piece_output = output_from_text(the_object[this_piece], format);
            if (format == "pretext" && output_tag == "md" && this_piece == "content") {
                // convert \cr to mrow
                this_piece_output = this_piece_output.replace(/\s*\\cr\b\s*/g, "</mrow>\n<mrow>\n");
                this_piece_output = "<mrow>\n" + this_piece_output + "\n</mrow>";
            }
            the_answer += wrap_tag(this_tag, this_piece_output, [])
        } else {
            editorLog("missing piece:", this_tag, "with no", this_piece)
        }
    }

    // pretty print the output
    if (format == "pretext" && !(inline_tags.includes(output_tag)) && !(inline_math.includes(output_tag))) {
        the_answer = the_answer.replace(/(^|\n)( *(\w|<))/g, "$1  $2");
    }
    the_answer = wrap_tag(output_tag, the_answer, output_attributes_values)
//    editorLog("now the answer is", the_answer);

    return the_answer
}

function output_from_text(text, format) {
    editorLog("output_from_text of ", text, "with format", format);
    if (text.includes("<&>")) {
  //      return text.replace(/\s*<&>(.*?)<;>\s*/g, function (match, newid) { return output_from_id(match, newid, format)})
        return text.replace(/<&>(.*?)<;>/g, function (match, newid) { return output_from_id(match, newid, format)})
    } else {
        return text
    }
}

function output_from_id(match, the_id, format) {
    var the_answer = "";
    editorLog("expanding the_id", the_id);
    debugLog("expanding the_id", the_id);
    var the_object = internalSource[the_id];
    if (!the_object) {
        errorLog("error: no content for", the_id);
        return the_id
    }
    var src_tag = the_object.sourcetag;
    editorLog("the_object",the_object);
    var output_structure;
    if (src_tag in objectStructure) {
        output_structure = objectStructure[src_tag][format];
    } else {
        errorLog("error: unknown structure:", src_tag);
        // so make reasonable assumptions about the structure
        output_structure = {
            "tag": src_tag,
            "pieces": [["content", ""]]
        }
    }

    editorLog("output_structure", output_structure);
 //   var output_tag = output_structure.tag;

    the_answer = output_from_source(the_object, output_structure, format);

    return the_answer
}

function expand_condensed_source_html(text, context) {
    editorLog("iiiiiii     in expand_condensed_source_html");
    if (text.includes("<&>")) {
        editorLog("     qqqqq      expand_condensed_source_html", text);
        if (context == "edit") {
            return text.replace(/<&>(.*?)<;>/g,expand_condensed_src_edit)
         } else {
            return text.replace(/<&>(.*?)<;>/g,expand_condensed_src_html)
         }
    } else {
    editorLog("returning text XX" + text.substring(0,17) + "YY");
    editorLog("returning from expand_condensed_source_html");
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
       // maybe saying it better:  sometimes we want to create an object and
       // insert it into the DOM.  Other times we just want to construct the
       // HTML markup fo rthe object and return that.
    var the_object = internalSource[the_id];
    editorLog("making html of", the_object, "is_inner", is_inner, "the_id", the_id);
    var sourcetag = the_object["sourcetag"];
    editorLog("which has tag", sourcetag);

    editorLog("m in inline_math", inline_math.includes("m"));

    var html_of_this_object;
    var the_html_objects = [];

    if (sourcetag == "image") {
        html_of_this_object = output_from_id("", the_id, "html");
        editorLog("html_of_this_object", html_of_this_object);
        the_html_objects.push(html_of_this_object);
    } else if (tag_type(sourcetag) == "p") {
        html_of_this_object = output_from_id("", the_id, "html");
        editorLog("html_of_this_object", html_of_this_object);
        the_html_objects.push(html_of_this_object);
    } else if (inline_math.includes(sourcetag) && is_inner == "edit") {
        // here we are assuming the tag is 'm'
        var opening_tag = '<span class="edit_inline_math"';
        var closing_tag = '</span>';
            opening_tag += ' id="' + the_id + '"data-editable="44" tabindex="-1">';
        return opening_tag + spacemath_to_tex(the_object["content"]) + closing_tag
    } else if (["me","men"].includes(sourcetag) && is_inner == "edit") {
        var opening_tag = '<div class="edit_display_math"';
        var closing_tag = '</div>';
            opening_tag += ' id="' + the_id + '"data-editable="44" tabindex="-1">';
        return opening_tag + spacemath_to_tex(the_object["content"]) + closing_tag
    } else if (["md","mdn"].includes(sourcetag) && is_inner == "edit") {
        var opening_tag = '<div class="edit_multiline_math"';
        var closing_tag = '</div>';
            opening_tag += ' id="' + the_id + '"data-editable="44" tabindex="-1">';
        this_content = the_object["content"].replace(/<&>(.*?)<;>/g,expand_condensed_src_edit);
        this_content = this_content.replace("MROWsepARATOR", "\n yyyy \n");
        return opening_tag + this_content + closing_tag
    } else if (["mrow"].includes(sourcetag) && is_inner == "edit") {
        var opening_tag = '<div class="edit_math_row"';
        var closing_tag = '</div>';
            opening_tag += ' id="' + the_id + '"data-editable="44" tabindex="-1">';
        return opening_tag + "MROW" + spacemath_to_tex(the_object["content"]) + closing_tag
    } else if (sourcetag == "xref" && is_inner == "edit") {
        // here we are assuming the tag is 'm'
        var opening_tag = '<span class="edit_reference"';
        var closing_tag = '</span>';
            opening_tag += ' id="' + the_id + '"data-editable="44" tabindex="-1">';
        return opening_tag + the_object["ref"] + closing_tag
    } else {
        html_of_this_object = output_from_id("", the_id, "html");
        editorLog("html_of_this_object", html_of_this_object);
        the_html_objects.push(html_of_this_object);

    } 

    editorLog("    RRRR returning the_html_objects", the_html_objects);

//    the_html_objects = the_html_objects.replace("MROWsepARATOR", "\n\\cr\n");
    return the_html_objects
}

function insert_html_version(these_changes) {

    var nature_of_the_change = these_changes[0];
    var location_of_change = these_changes[1];
    var possibly_changed_ids_and_entry = these_changes[2];

    editorLog("nature_of_the_change", nature_of_the_change);
    editorLog("location_of_change", location_of_change);
    editorLog("possibly_changed_ids_and_entry", possibly_changed_ids_and_entry);

    if (!possibly_changed_ids_and_entry.length) {
        editorLog("nothing to change");
  //      return ""
    }
    // we make HTML version of the objects with ids possibly_changed_ids_and_entry,
    // and then insert those into the page.  

// here is where we detect deleting?
// or is that after this function is done?
    if (nature_of_the_change != "replace") {
        editorLog("should be replace, since it is the edit form we are replacing");
    }

    var object_as_html = "";
    var this_object_id, this_object_entry, this_object_oldornew, this_object;

    editorLog(" there are", possibly_changed_ids_and_entry.length, "items to process");

    for (var j=0; j < possibly_changed_ids_and_entry.length; ++j) {
        this_object_id = possibly_changed_ids_and_entry[j][0];
        this_object_entry = possibly_changed_ids_and_entry[j][1];
        this_object_oldornew = possibly_changed_ids_and_entry[j][2];
        editorLog("j=", j, "this thing", possibly_changed_ids_and_entry[j]);
        this_object = internalSource[this_object_id];
        editorLog(j, "this_object", this_object);
        if (tag_type(this_object["sourcetag"]) == "p" || this_object["sourcetag"] == "li" || tag_type(this_object["sourcetag"]) == "md") {

            var this_new_object = html_from_internal_id(this_object_id);
            editorLog("inserting",this_new_object,"before",location_of_change);
            location_of_change.insertAdjacentHTML('beforebegin', this_new_object[0]);
            object_as_html = document.getElementById(this_object_id);

        } else if (this_object_entry == "title") {
            var object_as_html = document.createElement('span');
            object_as_html.setAttribute("class", "title");
            object_as_html.setAttribute('data-editable', 20);
            object_as_html.setAttribute('tabindex', -1);
       // next line should apply a transform to the source
            object_as_html.innerHTML = this_object[this_object_entry];
            editorLog("inserting",object_as_html,"before",location_of_change);
            // location_of_change is the .header .  We want it to be the .title
            location_of_change = location_of_change.querySelector("#actively_editing");
            editorLog("now location_of_change",location_of_change);
            location_of_change.insertAdjacentElement('beforebegin', object_as_html);
        } else if (this_object_entry == "caption") {
            console.log("Error: don't know what to do with 'caption'")
        } else if (this_object_entry == "image") {
            editorLog("image, this_object", this_object);
            var this_new_object = html_from_internal_id(this_object_id);
            editorLog("inserting",this_new_object,"before",location_of_change);
            location_of_change.insertAdjacentHTML('beforebegin', this_new_object[0]);
            object_as_html = document.getElementById(this_object_id);

        } else {
            editorLog("trouble making", this_object);
        }
        MathJax.typesetPromise();
//        MathJax.Hub.Queue(['Typeset', MathJax.Hub, this_object_id]);
    }
    location_of_change.remove();

    editorLog("returning from insert html version", object_as_html);
    // call mathjax, in case the new content contains math
    return object_as_html // the most recently added object, which we may want to
                           // do something, like add an editing menu
}  // insert html version

function save_edits() {

    var currentState = internalSource;

    editorLog("saving", currentState);
    localStorage.setObject("savededits", currentState);
    return "";
}

function previous_editing() {
    var old_internal_source = localStorage.getObject("savededits");
    return  (old_internal_source || "")
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
//   #choose_current
// 3rd option means we already have a menu

    if (document.getElementById("enter_choice")) {
        theEnterChoice = document.getElementById("enter_choice");
        editorLog("enter_choice", e);
        var theMotion = theEnterChoice.getAttribute("data-location");
        var object_of_interest;
        if (theMotion == "stay") {
            object_of_interest = theEnterChoice.parentElement.previousSibling;
        } else {
            object_of_interest = theEnterChoice.parentElement.parentElement;
        }
        editorLog("      MMN: want to", theMotion, "on", object_of_interest, "from", theEnterChoice)

        editorLog("current_editing", current_editing);
        editorLog("theEnterChoice", theEnterChoice);
        var current_level = current_editing["level"];
        var current_location = current_editing["location"][current_level];
        var current_siblings =  current_editing["tree"][current_level];
        editorLog("current_level", current_level, "current_location", current_location, "current_siblings", current_siblings);

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
            edit_submenu.setAttribute('class', 'edit_menu');

            var to_be_edited = object_of_interest;
            editorLog("to_be_edited", to_be_edited);
            edit_submenu.innerHTML = top_menu_options_for(to_be_edited);
            $("#enter_choice").replaceWith(edit_submenu);
            document.getElementById('choose_current').focus();
        }
        editorLog("   Just handled the case of enter_choice");
        return ""

    } else if (document.getElementById("choose_current")) {
        var theChooseCurrent = document.getElementById("choose_current");
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
        editorLog("in choose_current", dataLocation, "of", object_of_interest);
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
            next_menu_item.setAttribute("id", "choose_current");
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
                next_menu_item.setAttribute("id", "choose_current");
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
                    previous_menu_item.setAttribute("id", "choose_current");
                    previous_menu_item.focus();
                }
            }
      }
        else if (keyletters.includes(e.code)) {
        key_hit = e.code.toLowerCase().substring(3);  // remove forst 3 characters, i.e., "key"
        editorLog("key_hit", key_hit);
        theChooseCurrent = document.getElementById('choose_current');
        editorLog('theChooseCurrent',  theChooseCurrent );
        editorLog( $(theChooseCurrent) );
          // there can be multiple data-jump, so use ~= to find if the one we are looking for is there
          // and start from the beginning in case the match is earlier  (make the second selector better)
        if ((next_menu_item = $(theChooseCurrent).nextAll('[data-jump~="' + key_hit + '"]:first')[0]) ||
            (next_menu_item = $(theChooseCurrent).prevAll('[data-jump~="' + key_hit + '"]:last')[0])) {  // check there is a menu item with that key
            theChooseCurrent.removeAttribute("id", "choose_current");
            next_menu_item.setAttribute("id", "choose_current");
            next_menu_item.focus();
        } else {
            // not sure what to do if an irrelevant key was hit
            editorLog("that key does not match any option")
        }
    }

//  Now only Enter and ArrowRight are meaningful in this context.
//  The effect will depend on the other attributes of #choose_current:
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
                document.getElementById('choose_current').focus();
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
                document.getElementById('choose_current').focus();
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
                            edit_submenu.setAttribute('class', 'edit_menu');
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
                        document.getElementById('choose_current').focus();
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
                document.getElementById('choose_current').focus();
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
              $("#choose_current").parent().addClass("past");
              editorLog("apparently selected", theChooseCurrent);
              theChooseCurrent.removeAttribute("id");
              theChooseCurrent.setAttribute('class', 'chosen');

        //      if (dataEnv in inner_menu_for()) {  // object names a collection, so make submenu
              if (dataEnv in submenu_options) {  // object names a collection, so make submenu
                  editorLog("making a menu for", dataEnv);
                  var edit_submenu = document.createElement('ol');
                  edit_submenu.innerHTML = menu_options_for("", dataEnv, "inner");
                  theChooseCurrent.insertAdjacentElement("beforeend", edit_submenu);
                  document.getElementById('choose_current').focus();

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
                  theChooseCurrent.setAttribute("id", "choose_current");
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

function initialize_editing(xml_st) {

    createCookie(chosen_edit_option_key,1,0.01);
 //   console.log("QQQQQQQQ", xml_st, "PPPPPPPPPP");
    // Space Math uses a blank line to indicate mrows
    xml_st = xml_st.replace(/<\/mrow>\s*<mrow>/g, " \n\\cr\n ");
    xml_st = xml_st.replace(/<mrow>/g, " ");
    xml_st = xml_st.replace(/<\/mrow>/g, " ");

    xmlToObject(xml_st);
    record_children(sourceobj);
    internalSource = re_transform_source();

    console.log("mostly done initializing");
    console.log(internalSource);

    current_editing = {
        "level": 0,
        "location": [0],
 //       "tree": [ [document.getElementById(top_level_id)] ]
        "tree": [ [internalSource.root_data.id] ]
    }
    console.log("initial current_editing", current_editing);

    e_tree = current_editing["tree"];
    editorLog("e_tree", e_tree);
    e_level = current_editing["level"];
    editorLog("e_level", e_level);
    e_location = current_editing["location"];
    editorLog("e_location", e_location);
    console.log("               making the initial menu for", e_tree[e_level][e_location]);

//    document.getElementById("content").firstElementChild.setAttribute("id", internalSource.root_data.id);

    console.log("replacing by id", internalSource.root_data.id);
    replace_by_id(internalSource.root_data.id, "html");

    edit_menu_for(e_tree[e_level][e_location], "entering")

    console.log("internalSource internalSource internalSource internalSource internalSource internalSource", internalSource);

   // done rebulding HTML, so now process math
   // NOT CURRENTLY DOING ANYTHING????
    console.log("ready to edit, so typeset the math");
    document.getElementById("content").classList.add("canedit");
    MathJax.typesetPromise();
}

var this_source_txt;    
var source_url = window.location.href;
source_url = source_url.replace(/(#|\?).*/, "");
source_url = source_url.replace(/html$/, "ptx");
fetch(source_url).then(
        function(u){ return u.text();}
      ).then(
        function(text){
          this_source_txt = text;
  //        console.log("ppppppppppp  this_source_txt",this_source_txt)
          if (this_source_txt.includes("404 Not")) {
              console.log("Error: source unavailable")
          } else if (this_source_txt.includes("<biblio ")) {
              console.log("Editing bibliographies not implemented")
          } else if( false && editing_mode) {
              initialize_editing(this_source_txt)
          } else {
              console.log("editing_mode", editing_mode)
              edit_choice = document.createElement('span');
              edit_choice.setAttribute("class", "login-link");
      //        edit_choice.innerHTML = "<span id='edit_choice'>Edit this page</span>";
    //          document.getElementById("content").insertAdjacentElement("afterbegin", edit_choice);
              if(editing_mode) {
                  initialize_editing(this_source_txt)
             //     edit_choice.innerHTML = "<span id='edit_choice'>Stop editing this page</span>";
                  edit_choice.innerHTML = "";
              } else {
                  edit_choice.innerHTML = "<span id='edit_choice'>Edit this page</span>";
              }
              document.getElementById("ptx-content").insertAdjacentElement("beforeend", edit_choice);
              console.log("editing choice enabled")
              $("#edit_choice").on("click", function(event){
                  console.log("apparently you want to edit");
                  initialize_editing(this_source_txt)
                  document.getElementById("edit_choice").remove();
              });
          }
        }
      );

console.log("fetched source");


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

var sourceobj = {};
var new_top_id = "";

function xmlToObject(xml_st) {
  var xml;
  if (typeof xml_st == "string") {
 //   parseLog("xml starts", xml_st.slice(0,50));
    parser = new DOMParser();
    xml = parser.parseFromString(xml_st, "text/xml");
//    xml = $.parseXML(xml_st);
  } else {
    xml = xml_st
  }

  parseLog("xml", xml);
  parseLog("xml.nodeName", xml.nodeName, "xml.nodeType", xml.nodeType);
//  var obj = {};
  var this_id = "";
  var this_node_content = xml.nodeValue;

  if (xml.nodeType == 9) {  // document              
      xml = xml.documentElement;
  }

  parseLog("this_node_content", this_node_content);

  if (xml.nodeType == 1) { // element                
    this_id = xml_id_of(xml);
    if (!new_top_id) {
        new_top_id = this_id;
        top_level_id = new_top_id;
        sourceobj["root_data"] =  {"id": new_top_id, "number_base": "X.Y"}
    }
    parseLog("found this_id", this_id);
    var this_entry = {};
    this_entry["xml:id"] = this_id;
    if (["ol", "ul", "dl"].includes(xml.nodeName)) {
        this_entry["sourcetag"] = "list"
/*
    } else if (["me", "men"].includes(xml.nodeName)){
        this_entry["sourcetag"] = "displaymath"
*/
    } else {
        this_entry["sourcetag"] = xml.nodeName;
    }

    this_node_content = "";
    if (xml.hasChildNodes()) {
      for (var i = 0; i < xml.childNodes.length; i++) {
        var item = xml.childNodes.item(i);
        if (item.nodeType == 8) {
            //comment, so skip
        } else if (item.nodeType == 3) { // text
            this_node_content += item.nodeValue
        } else if (item.nodeType == 1) { // element
            var sub_node_id = xmlToObject(item);  // the contents, in certain cases
            if (contained_objects.includes(item.nodeName)) {
                this_entry[item.nodeName] = sub_node_id
            } else {
                this_node_content += "<&>" + sub_node_id + "<;>"
            }
        } else {
            parseLog("what to do with this node?", item)
        }
      }
    }    
    if (this_node_content) {
        this_entry["content"] = this_node_content.trim();
    }

    if (xml.attributes.length > 0) {
      //  parseLog(xml.nodeName, "has attributes", xml.attributes);
        for (var j = 0; j < xml.attributes.length; j++) {
            var attribute = xml.attributes.item(j);
            if (attribute.nodeName == "source") { this_entry["source"] = attribute.nodeValue }
            else if (attribute.nodeName == "ref") { this_entry["ref"] = attribute.nodeValue }
            else if (attribute.nodeName == "text") { this_entry["text"] = attribute.nodeValue }
  // width for images, widths for sbs
            else if (attribute.nodeName == "width") {
                var widthvalue = attribute.nodeValue;
                if (widthvalue.endsWith("%")) { widthvalue = widthvalue.slice(0,-1); }
                this_entry["width"] = widthvalue
            } else if (attribute.nodeName == "margins") {
                var marginsvalues = attribute.nodeValue.split(' ');
                if (marginsvalues.length == 1) {
                    var margin = marginsvalues[0];
                    if (margin.endsWith("%")) { margin = margin.slice(0,-1); }
                    this_entry["marginleft"] = margin;
                    this_entry["marginright"] = margin;
                } else if (marginsvalues.length == 2) {
                    var [marginleft, marginright] = marginsvalues;
                    if (marginleft.endsWith("%")) { marginleft = marginleft.slice(0,-1); }
                    if (marginright.endsWith("%")) { marginright = marginright.slice(0,-1); }
                    this_entry["marginleft"] = marginleft;
                    this_entry["marginright"] = marginright;
                } else {
                    console.log("Error: too many margins in", xml)
                }
            }
        }
    }
    // The CAT expects a width and margins on an image, but those myght not be
    // specified in the source.  So add those if not present.
    if (xml.nodeName == "image") {
        console.log("image attributes", xml.attributes, "ddd", xml.attributes["source"]);
        if (!xml.attributes["width"]) {
            console.log("no width");
            this_entry["width"] = 100;
        }
        if (!xml.attributes["margins"]) {
            console.log("no margins");
            this_entry["marginleft"] = 0;
            this_entry["marginright"] = 0;
        }
    }

    if (xml.attributes) {
        parseLog(xml, "has attributes", xml.attributes)
    }
//    parseLog("item", item);
    if (contained_objects.includes(xml.nodeName)) {
        return this_node_content
    } else {
        sourceobj[this_id] = this_entry
        return this_id
    }
  } else if (xml.nodeType == 8) {
      // comment node, so do nothing
      this_node_content = ""
  } else if (xml.nodeType == 3) {  // text
      // can this, or the previous case, actually happen?
  } else {
      console.log("failed to deal with", xml)
  }
}

function record_children(internal_src) {
    for (key in internal_src) {
        var this_item = internal_src[key];
        if ("content" in this_item) { // skip empty tags
            var this_content = this_item["content"];
            parseLog("this_content", this_content);
            var child_items = this_content.match(/<&>.*?<;>/g) || "";
            for (var j=0; j < child_items.length; ++j) {
                var this_child = child_items[j].slice(3,-3);
                parseLog("this_child", this_child, "has a parent", key);
                internal_src[this_child]["parent"] = [key, "content"]
            }
        }
  // need to handle content and statement better
        if ("statement" in this_item) { // skip empty tags
            var this_statement = this_item["statement"];
       //     parseLog("this_statement", this_statement);
            var child_items = this_statement.match(/<&>.*?<;>/g) || "";
            for (var j=0; j < child_items.length; ++j) {
                var this_child = child_items[j].slice(3,-3);
        //        parseLog("this_child", this_child, "has a parent", key);
                internal_src[this_child]["parent"] = [key, "statement"]
            }
        }
        if ("proof" in this_item) { // skip empty tags
            var this_proof = this_item["proof"];
       //     parseLog("this_statement", this_statement);
            var child_items = this_proof.match(/<&>.*?<;>/g) || "";
            for (var j=0; j < child_items.length; ++j) {
                var this_child = child_items[j].slice(3,-3);
        //        parseLog("this_child", this_child, "has a parent", key);
                internal_src[this_child]["parent"] = [key, "proof"]
            }
        }
    }
    return internal_src
}

// transofrm again, to un-wrap list in p

/* rewrite with sourceobj not global */
function re_transform_source() {
  var ids_to_delete = [];
  for (var id in sourceobj) {
    var this_item = sourceobj[id];
    if (this_item["sourcetag"] == "list") {
        // I think this takes the list out of its parent p,
        // but I forgot to write this comment when I first wrote the code.
        parseLog("found a list", this_item);
        var [parent_id, parent_content] = this_item["parent"];
        parseLog("with parent", sourceobj[parent_id]);
        if (sourceobj[parent_id]["sourcetag"] == "p") {
            var [parent_parent_id, parent_parent_content] = sourceobj[parent_id]["parent"];
            parseLog("with parents parent", sourceobj[parent_parent_id]);
            // need to skip the intermediate parent
            var old_p_p_content = sourceobj[parent_parent_id][parent_parent_content];
            var new_p_p_content = old_p_p_content.replace("<&>" + parent_id + "<;>", "<&>" + id + "<;>");
            sourceobj[parent_parent_id][parent_parent_content] = new_p_p_content;
            sourceobj[id]["parent"] = [parent_parent_id, parent_parent_content];
            // then eliminate the intermediate parent
            parseLog("deleting", parent_id);
       //     delete sourceobj[parent_id];
            ids_to_delete.push(parent_id);
            parseLog("now sourceobj[parent_parent_id]", sourceobj[parent_parent_id])
        }
    } else if (this_item["sourcetag"] == "image") {
        if ("width" in this_item && !("marginleft" in this_item)) {
            parseLog("no width in" + this_item["xml:id"])
            var width = parseInt(this_item["width"]);
            var margins = (100 - width)*0.5;
            this_item["marginleft"] = margins;
            this_item["marginright"] = margins;
        }
    } else if (["md", "mdn", "me", "men"].includes(this_item["sourcetag"])) {
  // to handle the case of more than one displaymath in a p,
  // we do it in two passes.  First we just record the ids of the me/men's.
  // Then we simplify the problem by handling the displaymath in the
  // order they occur.
        parseLog("found displaymath", this_item);
        parseLog("with parent", sourceobj[this_item["parent"][0]]);
        var displaymath_id= this_item["xml:id"];
        if ("includedmath" in sourceobj[this_item["parent"][0]]) {
            sourceobj[this_item["parent"][0]]["includedmath"].push("<&>" + displaymath_id + "<;>")
        } else {
            sourceobj[this_item["parent"][0]]["includedmath"] = ["<&>" + displaymath_id + "<;>"]
        }
    } else if (["caption"].includes(this_item["sourcetag"])) {
        parseLog("found a caption", this_item);
        var [parent_id, parent_content] = this_item["parent"];
        parseLog("with parent", sourceobj[parent_id]);
        if (sourceobj[parent_id]["sourcetag"] == "figure") {
            var old_p_content = sourceobj[parent_id][parent_content];
            var new_p_content = old_p_content.replace("<&>" + id + "<;>", "");
            sourceobj[parent_id][parent_content] = new_p_content;
            sourceobj[parent_id]["captiontext"] = sourceobj[id]["content"];
         // then eliminate the caption object, because now it is an attribute of a figure
         //   delete sourceobj[id];
            ids_to_delete.push(id);
            parseLog("now sourceobj[parent_id]", sourceobj[parent_id])
alert("testing")
        } else { alert("error: caption not in figure") }
    }
  }
  // now go through and fix the "p" containing displaymath
  for (var id in sourceobj) {
    var this_item = sourceobj[id];
    if (this_item["sourcetag"] == "p") {
        if ("includedmath" in this_item) {
            console.log("found includedmath", this_item);
            var outer_parent = this_item["parent"];
            var context_of_outer_parent = sourceobj[outer_parent[0]][outer_parent[1]];
            console.log("this item id", id, "with parent", outer_parent, "in context", context_of_outer_parent);
            var these_includedmath = this_item["includedmath"];
            var this_content = this_item["content"];
            var these_includedmath_index = [];
            for (var j=0; j < these_includedmath.length; ++j) {
                var this_math_tag = these_includedmath[j];
                these_includedmath_index.push([this_content.indexOf(this_math_tag),this_math_tag]);
                console.log("this_math_tag", this_math_tag, "has index", this_content.indexOf(this_math_tag))
            }
            these_includedmath_index.sort();
            parseLog("sorted list", these_includedmath_index)

      //      var displaymath_parent_original_content = sourceobj[outer_parent[0]]["content"];
            parseLog("ocntent before splitting up", context_of_outer_parent);
            this_math_tag = these_includedmath_index[0][1];
            parseLog("this_math_tag", this_math_tag);
            var this_math_id = this_math_tag.slice(3,-3);
            parseLog("this_math_id", this_math_id);
            parseLog("with source", sourceobj[this_math_id]);
            // move punctuation inside the display math
            // (for easier editing.  move it back out later)
            var find_char_after = new RegExp('^(.*' + this_math_tag + ")(.)\s*(.*)$", "s");
            var char_after = this_content.replace(find_char_after, "$2");
            if ([".", ",", ";", ":"].includes(char_after)) {
                console.log("found punctuation", char_after);
                this_content = this_content.replace(find_char_after, "$1$3");  // go back an omit white space
                sourceobj[this_math_id]["content"] += char_after
            }
            // the original p ends at the first displaymath
            var displaymath_id_and_before = new RegExp('^.*' + this_math_tag, "s");  // s = dotAll
            var displaymath_id_and_after = new RegExp(this_math_tag + '.*$', "s");
            sourceobj[id]["content"] =
                   this_content.replace(displaymath_id_and_after, "");
            sourceobj[id]["sourcetag"] = "ip"
            this_content = this_content.replace(displaymath_id_and_before, "");
            parseLog("updated this_content", this_content);
            // the first displaymath now has a different parent
            sourceobj[this_math_id]["parent"] = outer_parent;
            // that parent needs to know where to put the first displaymath
            context_of_outer_parent = context_of_outer_parent.replace("<&>" + id + "<;>", "<&>" + id + "<;>" + "\n" + this_math_tag);
            parseLog("updated context_of_outer_parent", context_of_outer_parent);
            sourceobj[outer_parent[0]][outer_parent[1]] = context_of_outer_parent;
         //  here need to check if this_content is nonempty (after removing trailing white space
            var new_id = "XXXX" + randomstring();
            sourceobj[new_id] = {"xml:id":new_id, "sourcetag": "mp"};
            sourceobj[new_id]["content"] = this_content;
            sourceobj[new_id]["parent"] = outer_parent;
            context_of_outer_parent = context_of_outer_parent.replace(this_math_tag, this_math_tag + "\n" + "<&>" + new_id + "<;>");
            sourceobj[outer_parent[0]][outer_parent[1]] = context_of_outer_parent;
            for (var j=1; j < these_includedmath_index.length; ++j) {
                this_math_tag = these_includedmath_index[j][1];
                this_math_id = this_math_tag.slice(3,-3);

                // move punctuation inside the display math
                // (for easier editing.  move it back out later)
                var find_char_after = new RegExp('^(.*' + this_math_tag + ")(.)\s*(.*)$", "s");
                var char_after = this_content.replace(find_char_after, "$2");
                if ([".", ",", ";", ":"].includes(char_after)) {
                    console.log("found punctuation", char_after);
                    this_content = this_content.replace(find_char_after, "$1$3");  // go back an omit white space
                    sourceobj[this_math_id]["content"] += char_after
                } 

                displaymath_id_and_before = new RegExp('^.*' + this_math_tag, "s");  // s = dotAll
                displaymath_id_and_after = new RegExp(this_math_tag + '.*$', "s");
                sourceobj[new_id]["content"] = this_content.replace(displaymath_id_and_after, "");
                this_content = this_content.replace(displaymath_id_and_before, "");
                // this displaymath now has a different parent
                sourceobj[this_math_id]["parent"] = outer_parent;
                // that parent needs to know where to put the first displaymath
                context_of_outer_parent = context_of_outer_parent.replace("<&>" + new_id + "<;>", "<&>" + new_id + "<;>" + "\n" + this_math_tag);
                sourceobj[outer_parent[0]][outer_parent[1]] = context_of_outer_parent;
          // omit next if this_content is only white space
                new_id = "XXXX" + randomstring();
                sourceobj[new_id] = {"xml:id":new_id, "sourcetag": "mp"};
                sourceobj[new_id]["content"] = this_content;
                sourceobj[new_id]["parent"] = outer_parent;
                context_of_outer_parent = context_of_outer_parent.replace(this_math_tag, this_math_tag + "\n" + "<&>" + new_id + "<;>");
                sourceobj[outer_parent[0]][outer_parent[1]] = context_of_outer_parent;
            }
            sourceobj[new_id]["sourcetag"] = "fp"
        }
    }
  }
  // trim leading white space in paragraph content
  for (var id in sourceobj) {
    var this_item = sourceobj[id];
    if (["p", "ip", "mp", "fp"].includes(this_item["sourcetag"])) {
        var this_content = sourceobj[id]["content"];
        this_content = this_content.replace(/\n +/g, "\n");
        sourceobj[id]["content"] = this_content;
    } else if (["me", "men", "md", "mdn"].includes(this_item["sourcetag"])) {
        var this_content = sourceobj[id]["content"];
        this_content = this_content.replace(/\n +/g, "\n  ");
        sourceobj[id]["content"] = this_content;
    }
    // next also needs table (or whatever it is that has a caption)
    if (["figure"].includes(this_item["sourcetag"])) {
        editorLog("adjusting a figure", this_item);
   //  ??? next line should involve captiontext instead of caption ?
        var this_caption = sourceobj[id]["caption"];
        this_caption = this_caption.replace(/\n +/g, "\n");
        sourceobj[id]["captiontext"] = this_caption;
    }
  }

  for (var j=1; j < ids_to_delete.length; ++j) {
 //     delete sourceobj[ids_to_delete[j]]
  }

  return sourceobj;
}

