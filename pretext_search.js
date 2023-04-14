
//  window.addEventListener("load",function(event) {
//          var secondsearchbox = document.createElement("div");
//          secondsearchbox.className = "searchbox";
//          secondsearchbox.id = "secondsearch";
//          document.body.appendChild(secondsearchbox);
//          secondsearchbox.innerHTML = '<div class="searchwidget"><input id="ptxsearchB" type="text" name="terms" placeholder="Search" onchange="doSearch(\'B\')"><button id="searchbutton" type="button" onclick="doSearch(\'B\')">🔍</button> <div>'
//      console.log("added second search box");
//  });

// from lunr-pretext-search-index.js we will have either
// var ptx_lunr_search_style = "default";
//   or
// var ptx_lunr_search_style = "reference";

// since there is only one search box now, this can be simplified
function doSearch(searchlocation="A") {
    // Get the search terms from the input text box
    var terms;
    if(searchlocation == "A") {
        terms = document.getElementById("ptxsearch").value;
    } else {
        terms = document.getElementById("ptxsearchB").value;
    }
    // Where do we want to put the results?
    let resultArea = document.getElementById("searchresults")
    resultArea.innerHTML = "";  // clear out any previous results
    // assume AND for multiple words
    var searchterms = terms;
    if(searchlocation == "B") {
        document.getElementById("ptxsearch").value = searchterms
        console.log("ptxsearch value", document.getElementById("ptxsearch").value);
    } else {
        searchterms = terms;
//        document.getElementById("ptxsearchB").value = searchterms;
    }
    searchterms = searchterms.trim();
    searchterms = searchterms.replace(/ +/g, " ");
    searchterms = searchterms.replaceAll(" ", " +");
    searchterms = "+".concat(searchterms);
    // do the search using the provided index
    let pageResult = ptx_lunr_idx.search(searchterms);
    // Number the documents from first to last so we can order the results by their
    // position in the book.
    snum = 0;
    for (let doc of ptx_lunr_docs) {
        doc.snum = snum;
        snum += 1;
    }
    // Transfer meta data from the document to the results to make it easy to add 
    // our lists later.
console.log("pageResult", pageResult);
    augmentResults(pageResult, ptx_lunr_docs);
    pageResult.sort(comparePosition)
    REaugmentResults(pageResult);
    addResultToPage(terms, pageResult, ptx_lunr_docs, resultArea);
    MathJax.typeset();
}

// Find the entry for a search result in the original document index
function findEntry(resultId, db) {
    for (const page of db) {
        if (page.id === resultId) {
            return page;
        }
    }
    return resultId;
}

function augmentResults(result, docs) {
    for (let res of result) {
        let info = findEntry(res.ref, docs);
        res.number = info.number;
        res.type = info.type;
        res.title = info.title;
        res.url = info.url;
        res.level = info.level;
        res.snum = info.snum;
    }
}
// have to rewrite this with a variable for the index, because we have to
// remember the location.
// but probably this step is not actually needed, because of rearrangeArray
function REaugmentResults(result) {
    let currenttopindex = 0;
    // assume only level 1 and 2 in results
    for (let index = 0; index < result.length; ++index) {
        res = result[index];
        res.order = index;
        if (res.level == 2) { res.parent = currenttopindex }
        else if (res.level == 1) { currenttopindex = index }
    }
}
function rearrangedArray(arry) {
   // return a new array which is arry (with depth) sorted according to meas,
   // again as an array with depth.
   // "with depth'' means that large children drag along their parents.
   let newarry = [];
   let startind = 0;
   let numtograb = 0;
   let ct = 1;
   while (arry.length > 0 && ct < 500) {
++ct;
       const locofmax = maxLocation(arry)
       let segmentstart = locofmax;
       let segmentlength = 1;
       while (arry[segmentstart].level == "2") {
           --segmentstart
       }
       while (segmentstart + segmentlength < arry.length && arry[segmentstart + segmentlength].level == "2") {
           ++segmentlength
       }
console.log("locofmax", locofmax, "starting", segmentstart, "going", segmentlength, "from", arry.length);
       newarry.push(...arry.splice(segmentstart,segmentlength));
   }
console.log("newarry", newarry);
    return newarry
}
function maxLocation(arry) {
    let maxloc = 0;
    let maxvalsofar = -1;
    for (let index = 0; index < arry.length; ++index) {
        if (arry[index].score > maxvalsofar) {
            maxloc = index;
            maxvalsofar = arry[index].score
        }
    }
    return maxloc
}

function comparePosition(a, b) {
    if (a.snum < b.snum) {
        return -1;
    }
    if (a.snum > b.snum) {
        return 1;
    }
    return 0;
}
function compareScoreDesc(a, b) {
    if (a.score < b.score) {
        return 1;
    }
    if (a.score > b.score) {
        return -1;
    }
    return 0;
}

function addResultToPage(searchterms, result, docs, resultArea) {
    /* backward compatibility for old html */
    if (document.getElementById("searchempty")) {
        document.getElementById("searchempty").style.display = "none";
    }
    document.getElementById("searchterms").innerHTML = searchterms;
    let len = result.length;
    console.log("first result", result[0]);
    if (len == 0) {
        if (document.getElementById("searchempty")) {
            document.getElementById("searchempty").style.display = "block";
        } else {
            let noresults = document.createElement("div");
            noresults.classList.add("noresults");
            search_no_results_string = "No results were found"
            noresults.innerHTML = search_no_results_string + ".";
   //     console.log("the new variable", search_results_heading_string);
            resultArea.appendChild(noresults);
        }
        document.getElementById("searchresultsplaceholder").style.display = "block";
        return
    }
console.log("result",result);
    let allScores = result.map(function (r) { return r.score });
console.log("allScores",allScores);
    allScores.sort();
    allScores.reverse();

//    let high = result[Math.floor(len*0.25)].score;
//    let med = result[Math.floor(len*0.5)].score;
//    let low = result[Math.floor(len*0.75)].score;
    // sort the results by their position in the book, not their score
    let high = allScores[Math.floor(len*0.25)];
    let med = allScores[Math.floor(len*0.5)];
    let low = allScores[Math.floor(len*0.75)];
    if (ptx_lunr_search_style == "reference") {
        result = rearrangedArray(result);
        }
    let indent = "1";
    let currIndent = indent;
    let origResult = resultArea;
    // Create list entries indenting as needed.  
    for (const res of result) {
        let link = document.createElement("a")
        // add a class so we can colorize the results based on their rank in terms
        // of search score.
        if (res.score >= high) {
            link.classList.add("high_result")
        } else if (res.score >= med) {
            link.classList.add("medium_result")
        } else if (res.score >= low) {
            link.classList.add("low_result")
        } else { 
            link.classList.add("no_result")
        }
        currIndent = res.level;
        if (currIndent > indent) {
            indent = currIndent;
            let ilist = document.createElement("ul")
            ilist.classList.add("detailed_result");
            resultArea.appendChild(ilist);
            resultArea = ilist;
        } else if (currIndent < indent) {
            resultArea = origResult;
            indent = currIndent;
        }
        let bullet = document.createElement("li")
        bullet.style.marginTop = "5px";
        link.href = `${res.url}`;
        link.innerHTML = `${res.type} ${res.number} ${res.title}`;
        bullet.appendChild(link)
        let p = document.createElement("text");
        p.innerHTML = `  (${res.score.toFixed(2)})`;
        bullet.appendChild(p);
        resultArea.appendChild(bullet);
    }
    document.getElementById("searchresultsplaceholder").style.display = "block";
    MathJax.typesetPromise();
}


function showHelp() {
    let state = document.getElementById("helpme").style.display;
    if (state == "none") {
        document.getElementById("helpme").style.display = "block";
        document.getElementById("helpbutt").innerHTML = "Hide Help"
    } else {
        document.getElementById("helpme").style.display = "none";
        document.getElementById("helpbutt").innerHTML = "Show Help"
    }
}
