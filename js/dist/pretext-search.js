(() => {
  // ../../js/src/search.js
  function findEntry(resultId, db) {
    for (const page of db) {
      if (page.id === resultId) return page;
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
      const LEVEL_WEIGHTS = [3, 2, 1.5];
      if (res.level < 2) res.score *= LEVEL_WEIGHTS[res.level];
      res.body = "";
      const REVEAL_WINDOW = 30;
      let titleMarked = false;
      for (const hit in res.matchData.metadata) {
        if (res.matchData.metadata[hit].title) {
          if (!titleMarked) {
            if (!res.matchData.metadata[hit].title.position)
              continue;
            let positionData = res.matchData.metadata[hit].title.position[0];
            const startClipInd = positionData[0];
            const endClipInd = positionData[0] + positionData[1];
            res.title = res.title.substring(0, endClipInd) + "</span>" + res.title.substring(endClipInd);
            res.title = res.title.substring(0, startClipInd) + '<span class="search-result-clip-highlight">' + res.title.substring(startClipInd);
            titleMarked = true;
          }
        } else if (res.matchData.metadata[hit].body) {
          if (!res.matchData.metadata[hit].body.position)
            continue;
          const bodyContent = info.body;
          let positionData = res.matchData.metadata[hit].body.position[0];
          const startInd = positionData[0] - REVEAL_WINDOW;
          const endInd = positionData[0] + positionData[1] + REVEAL_WINDOW;
          const startClipInd = positionData[0];
          const endClipInd = positionData[0] + positionData[1];
          let resultSnippet = (startInd > 0 ? "..." : "") + bodyContent.substring(startInd, startClipInd);
          resultSnippet += '<span class="search-result-clip-highlight">' + bodyContent.substring(startClipInd, endClipInd) + "</span>";
          resultSnippet += bodyContent.substring(endClipInd, endInd) + (endInd < bodyContent.length ? "..." : "") + "<br/>";
          res.body += resultSnippet;
        }
      }
    }
  }
  function rearrangedArray(arry) {
    let newarry = [];
    let ct = 1;
    while (arry.length > 0 && ct < 500) {
      ++ct;
      const locofmax = maxLocation(arry);
      let segmentstart = locofmax;
      let segmentlength = 1;
      while (arry[segmentstart].level == "2") {
        --segmentstart;
      }
      while (segmentstart + segmentlength < arry.length && arry[segmentstart + segmentlength].level == "2") {
        ++segmentlength;
      }
      newarry.push(...arry.splice(segmentstart, segmentlength));
    }
    return newarry;
  }
  function maxLocation(arry) {
    let maxloc = 0;
    let maxvalsofar = -1;
    for (let index = 0; index < arry.length; ++index) {
      if (arry[index].score > maxvalsofar) {
        maxloc = index;
        maxvalsofar = arry[index].score;
      }
    }
    return maxloc;
  }
  function comparePosition(a, b) {
    if (a.snum < b.snum) return -1;
    if (a.snum > b.snum) return 1;
    return 0;
  }
  function addResultToPage(searchterms, result, docs, numUnshown, resultArea) {
    if (document.getElementById("searchempty")) {
      document.getElementById("searchempty").style.display = "none";
    }
    let len = result.length;
    if (len == 0) {
      if (document.getElementById("searchempty")) {
        document.getElementById("searchempty").style.display = "block";
      } else {
        let noresults = document.createElement("div");
        noresults.classList.add("noresults");
        noresults.innerHTML = "No results were found.";
        resultArea.appendChild(noresults);
      }
      document.getElementById("searchresultsplaceholder").style.display = null;
      return;
    }
    let allScores = result.map(function(r) {
      return r.score;
    });
    allScores.sort((a, b) => a - b);
    allScores.reverse();
    let high = allScores[Math.floor(len * 0.2)];
    let med = allScores[Math.floor(len * 0.4)];
    let low = allScores[Math.floor(len * 0.75)];
    if (typeof ptx_lunr_search_style !== "undefined" && ptx_lunr_search_style == "reference") {
      result = rearrangedArray(result);
    }
    let indent = "1";
    let currIndent = indent;
    let origResult = resultArea;
    for (const res of result) {
      let link = document.createElement("a");
      if (res.score >= high) {
        link.classList.add("high_result");
      } else if (res.score >= med) {
        link.classList.add("medium_result");
      } else if (res.score >= low) {
        link.classList.add("low_result");
      } else {
        link.classList.add("no_result");
      }
      currIndent = res.level;
      if (currIndent > indent) {
        indent = currIndent;
        let ilist = document.createElement("ul");
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
      bullet.classList.add("search-result-bullet");
      bullet.appendChild(link);
      bullet.appendChild(clip);
      let p = document.createElement("text");
      p.classList.add("search-result-score");
      p.innerHTML = `  (${res.score.toFixed(2)})`;
      bullet.appendChild(p);
      resultArea.appendChild(bullet);
    }
    const resultsDiv = document.getElementById("searchresultsplaceholder");
    const backDiv = document.querySelector(".searchresultsbackground");
    resultArea.querySelectorAll("a").forEach((link) => {
      link.addEventListener("click", (e) => {
        backDiv.style.display = "none";
        resultsDiv.style.display = "none";
      });
    });
    document.getElementById("searchresultsplaceholder").style.display = null;
    MathJax.typesetPromise();
  }
  function doSearch(searchlocation = "A") {
    let terms;
    if (searchlocation == "A") {
      terms = document.getElementById("ptxsearch").value;
    } else {
      terms = document.getElementById("ptxsearchB").value;
    }
    localStorage.setItem(
      "last-search-terms",
      JSON.stringify({ terms, time: Date.now() })
    );
    let resultArea = document.getElementById("searchresults");
    resultArea.innerHTML = "";
    let searchterms = terms;
    if (searchlocation == "B") {
      document.getElementById("ptxsearch").value = searchterms;
    }
    searchterms = searchterms.toLowerCase().trim();
    let pageResult = [];
    if (searchterms != "") {
      pageResult = ptx_lunr_idx.query((q) => {
        for (let term of searchterms.split(" ")) {
          q.term(term, { fields: ["title"], boost: 20 });
          q.term(term, {
            wildcard: lunr.Query.wildcard.TRAILING,
            fields: ["title"],
            boost: 10
          });
          q.term(term, { fields: ["body"], boost: 5 });
          q.term(term, {
            wildcard: lunr.Query.wildcard.TRAILING,
            fields: ["body"]
          });
        }
      });
    }
    let snum = 0;
    for (let doc of ptx_lunr_docs) {
      doc.snum = snum;
      snum += 1;
    }
    const MAX_RESULTS = 100;
    let numUnshown = pageResult.length > MAX_RESULTS ? pageResult.length - MAX_RESULTS : 0;
    pageResult = pageResult.slice(0, MAX_RESULTS);
    augmentResults(pageResult, ptx_lunr_docs);
    pageResult.sort(comparePosition);
    addResultToPage(
      terms,
      pageResult,
      ptx_lunr_docs,
      numUnshown,
      resultArea
    );
    MathJax.typeset();
  }
  function initSearch() {
    const resultsDiv = document.getElementById("searchresultsplaceholder");
    if (!resultsDiv) return;
    const backDiv = document.createElement("div");
    backDiv.classList.add("searchresultsbackground");
    backDiv.style.display = "none";
    resultsDiv.parentNode.appendChild(backDiv);
    const searchButton = document.getElementById("searchbutton");
    if (searchButton) {
      searchButton.addEventListener("click", (e) => {
        resultsDiv.style.display = null;
        backDiv.style.display = null;
        let searchInput2 = document.getElementById("ptxsearch");
        const lastSearch = localStorage.getItem("last-search-terms");
        if (lastSearch) {
          searchInput2.value = JSON.parse(lastSearch).terms;
        }
        searchInput2.select();
        doSearch();
      });
    }
    const searchInput = document.getElementById("ptxsearch");
    if (searchInput) {
      searchInput.addEventListener("input", (e) => {
        doSearch();
      });
    }
    const closeButton = document.getElementById("closesearchresults");
    if (closeButton) {
      closeButton.addEventListener("click", (e) => {
        resultsDiv.style.display = "none";
        backDiv.style.display = "none";
        document.getElementById("searchbutton").focus();
      });
    }
  }

  // ../../js/src/pretext-search-entry.js
  window.addEventListener("load", function() {
    initSearch();
  });
})();
//# sourceMappingURL=pretext-search.js.map
