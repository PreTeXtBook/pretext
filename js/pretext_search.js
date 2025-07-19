
// next comment is out of date: there are more search options
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
    
    localStorage.setItem('last-search-terms', JSON.stringify({terms: terms, time: Date.now()}));
    
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
    }

    searchterms = searchterms.toLowerCase().trim();
    let pageResult = [];
    if(searchterms != "") {
        pageResult = ptx_lunr_idx.query((q) => {
            for(let term of searchterms.split(' ')) {
                q.term(term, { fields: ["title"], boost: 20 }); //exact title match with 20x weight
                q.term(term, { wildcard: lunr.Query.wildcard.TRAILING, fields: ["title"], boost: 10 }); //inexact title 10x weight
                q.term(term, { fields: ["body"], boost: 5 }); //exact body 5x weight
                q.term(term, { wildcard: lunr.Query.wildcard.TRAILING, fields: ["body"] }); //inexact body
            }
        });
    }
    // Number the documents from first to last so we can order the results by their
    // position in the book.
    snum = 0;
    for (let doc of ptx_lunr_docs) {
        doc.snum = snum;
        snum += 1;
    }

    //Limit to a sane number of results - otherwise search like 'e' matches every page
    const MAX_RESULTS = 100;
    let numUnshown = (pageResult.length > MAX_RESULTS) ? pageResult.length - MAX_RESULTS : 0;
    pageResult.slice(0, MAX_RESULTS);

    // Transfer meta data from the document to the results to make it easy to add 
    // our lists later.
    augmentResults(pageResult, ptx_lunr_docs);
    pageResult.sort(comparePosition);
    addResultToPage(terms, pageResult, ptx_lunr_docs, numUnshown, resultArea);
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
        res.score = parseFloat(res.score);

        //extra score multiplier based on level - prioritize sections over subsections/exercises/etc...
        const LEVEL_WEIGHTS = [3, 2, 1.5]
        if( res.level < 2 ) 
            res.score *= LEVEL_WEIGHTS[res.level];

        res.body = '';
        //Add body snippets and highlights
        const REVEAL_WINDOW = 30;
        let titleMarked = false;
        for (const hit in res.matchData.metadata) {
            if(res.matchData.metadata[hit].title) {
                //only show one match in title as locations change after first markup
                if(!titleMarked) {
                    if(!res.matchData.metadata[hit].title.position)
                        continue;
                    let positionData = res.matchData.metadata[hit].title.position[0];
                    const startClipInd = positionData[0];
                    const endClipInd = positionData[0] + positionData[1];
                    res.title = res.title.substring(0, endClipInd) + '</span>' + res.title.substring(endClipInd);
                    res.title = res.title.substring(0, startClipInd) + '<span class="search-result-clip-highlight">' + res.title.substring(startClipInd);
                    titleMarked = true;
                }
            } else if (res.matchData.metadata[hit].body) {
                if(!res.matchData.metadata[hit].body.position)
                    continue;
                const bodyContent = info.body;
                let positionData = res.matchData.metadata[hit].body.position[0];
                const startInd = positionData[0] - REVEAL_WINDOW;
                const endInd = positionData[0] + positionData[1] + REVEAL_WINDOW;
                const startClipInd = positionData[0];
                const endClipInd = positionData[0] + positionData[1];
                let resultSnippet = (startInd > 0 ? '...' : '' ) + bodyContent.substring(startInd, startClipInd);
                resultSnippet += '<span class="search-result-clip-highlight">' + bodyContent.substring(startClipInd, endClipInd) + '</span>';
                resultSnippet += bodyContent.substring(endClipInd, endInd) + (endInd < bodyContent.length ? '...' : '' ) + '<br/>';
                res.body += resultSnippet;
            }
        }
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
++ct;  // just in case something goes wrong
       const locofmax = maxLocation(arry)
       let segmentstart = locofmax;
       let segmentlength = 1;
       while (arry[segmentstart].level == "2") {
           --segmentstart
       }
       while (segmentstart + segmentlength < arry.length && arry[segmentstart + segmentlength].level == "2") {
           ++segmentlength
       }
// console.log("locofmax", locofmax, "starting", segmentstart, "going", segmentlength, "from", arry.length);
       newarry.push(...arry.splice(segmentstart,segmentlength));
   }
// console.log("newarry", newarry);
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

function addResultToPage(searchterms, result, docs, numUnshown, resultArea) {
    /* backward compatibility for old html */
    if (document.getElementById("searchempty")) {
        document.getElementById("searchempty").style.display = "none";
    }
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
        document.getElementById("searchresultsplaceholder").style.display = null;
        return
    }
// console.log("result",result);
    let allScores = result.map(function (r) { return r.score });
// console.log(typeof allScores[0], "allScores",allScores);
    allScores.sort((a,b) => (a - b));
    allScores.reverse();
// console.log("allScores, sorted",allScores);

//    let high = result[Math.floor(len*0.25)].score;
//    let med = result[Math.floor(len*0.5)].score;
//    let low = result[Math.floor(len*0.75)].score;
    // sort the results by their position in the book, not their score
    let high = allScores[Math.floor(len*0.20)];
    let med = allScores[Math.floor(len*0.40)];
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
        link.href = `${res.url}`;
        link.innerHTML = `${res.type} ${res.number} ${res.title}`;
        let clip = document.createElement("div");
        clip.classList.add("search-result-clip");
        clip.innerHTML = `${res.body}`;
        let bullet = document.createElement("li");
        bullet.classList.add('search-result-bullet');
        bullet.appendChild(link);
        bullet.appendChild(clip);
        let p = document.createElement("text");
        p.classList.add('search-result-score');
        p.innerHTML = `  (${res.score.toFixed(2)})`;
        bullet.appendChild(p);
        resultArea.appendChild(bullet);
    }

    // Auto-close search results when a result is clicked in case result is on
    // the same page search started from
    const resultsDiv = document.getElementById('searchresultsplaceholder');
    const backDiv = document.querySelector('.searchresultsbackground');
    resultArea.querySelectorAll("a").forEach((link) => {
        link.addEventListener('click', (e) => {
            backDiv.style.display = 'none';
            resultsDiv.style.display = 'none';
        });
    });
    //Could print message about how many results are not shown. No way to localize it though...
    // if(numUnshown > 0) {
    //     let bullet = document.createElement("li");
    //     bullet.classList.add('search-results-bullet');
    //     bullet.classList.add('search-results-unshown-count');
    //     let p = document.createElement("text");
    //     p.innerHTML = `${parseInt(numUnshown)} unshown results...`;
    //     bullet.appendChild(p);
    //     resultArea.appendChild(bullet);
    // }
    document.getElementById("searchresultsplaceholder").style.display = null;
    MathJax.typesetPromise();
}

window.addEventListener("load", function (event) {
    const resultsDiv = document.getElementById('searchresultsplaceholder');

    //insert a div to be backgroud behind searchresultsplaceholder
    const backDiv = document.createElement("div");
    backDiv.classList.add("searchresultsbackground");
    backDiv.style.display = 'none';
    resultsDiv.parentNode.appendChild(backDiv);

    document.getElementById("searchbutton").addEventListener('click', (e) => {
        resultsDiv.style.display = null;
        backDiv.style.display = null;
        let searchInput = document.getElementById("ptxsearch");
        searchInput.value = JSON.parse(localStorage.getItem("last-search-terms")).terms;
        searchInput.select();
        doSearch();
    });

    document.getElementById("ptxsearch").addEventListener('input', (e) => {
        doSearch();
    });

    document.getElementById("closesearchresults").addEventListener('click', (e) => {
        resultsDiv.style.display = 'none';
        backDiv.style.display = 'none';
        document.getElementById('searchbutton').focus();
    });
});
