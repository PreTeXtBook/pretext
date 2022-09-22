function doSearch() {
    // Get the search terms from the input text box
    let terms = document.getElementById("ptxsearch").value;
    // Where do we want to put the results?
    let resultArea = document.getElementById("searchresults")
    resultArea.innerHTML = "";  // clear out any previous results
    // do the search using the provided index
    let pageResult = ptx_lunr_idx.search(terms);
    // Number the documents from first to last so we can order the results by their
    // position in the book.
    snum = 0;
    for (let doc of ptx_lunr_docs) {
        doc.snum = snum;
        snum += 1;
    }
    // Transfer meta data from the document to the results to make it easy to add 
    // our lists later.
    augmentResults(pageResult, ptx_lunr_docs);
    addResultToPage(pageResult, ptx_lunr_docs, resultArea);
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


function comparePosition(a, b) {
    if (a.snum < b.snum) {
        return -1;
    }
    if (a.snum > b.snum) {
        return 1;
    }
    return 0;
}

function addResultToPage(result, docs, resultArea) {
    let len = result.length
    let high = result[Math.floor(len*0.25)].score;
    let med = result[Math.floor(len*0.5)].score;
    let low = result[Math.floor(len*0.75)].score;
    // sort the results by their position in the book, not their score
    result = result.sort(comparePosition)
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