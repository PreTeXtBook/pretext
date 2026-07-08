window.i18next = window.i18next || {
  t(key, params = {}) {
    for (const param in params) {
      key = key.replace(`{{${param}}}`, params[param]);
    }
    return key;
  }
};
function doSearch() {
  const terms = document.getElementById("ptx-search-terms").value;
  localStorage.setItem("last-search-terms", JSON.stringify({ terms, time: Date.now() }));
  let resultArea = document.getElementById("ptx-search-results");
  resultArea.innerHTML = "";
  const searchTerms = terms.toLowerCase().trim();
  let pageResult = [];
  if (searchTerms != "") {
    pageResult = ptx_lunr_idx.query((q) => {
      for (let term of searchTerms.split(" ")) {
        q.term(term, { fields: ["title"], boost: 20 });
        q.term(term, { wildcard: lunr.Query.wildcard.TRAILING, fields: ["title"], boost: 10 });
        q.term(term, { fields: ["body"], boost: 5 });
        q.term(term, { wildcard: lunr.Query.wildcard.TRAILING, fields: ["body"] });
      }
    });
  }
  snum = 0;
  for (let doc of ptx_lunr_docs) {
    doc.snum = snum;
    snum += 1;
  }
  const MAX_RESULTS = 100;
  let numUnshown = pageResult.length > MAX_RESULTS ? pageResult.length - MAX_RESULTS : 0;
  pageResult.slice(0, MAX_RESULTS);
  augmentResults(pageResult, ptx_lunr_docs);
  pageResult.sort(comparePosition);
  addResultToPage(terms, pageResult, ptx_lunr_docs, numUnshown, resultArea);
  MathJax.typeset();
}
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
    const LEVEL_WEIGHTS = [3, 2, 1.5];
    if (res.level < 2)
      res.score *= LEVEL_WEIGHTS[res.level];
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
          res.title = res.title.substring(0, startClipInd) + '<span class="ptx-search-result-clip-highlight">' + res.title.substring(startClipInd);
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
        resultSnippet += '<span class="ptx-search-result-clip-highlight">' + bodyContent.substring(startClipInd, endClipInd) + "</span>";
        resultSnippet += bodyContent.substring(endClipInd, endInd) + (endInd < bodyContent.length ? "..." : "") + "<br/>";
        res.body += resultSnippet;
      }
    }
  }
}
function rearrangedArray(arry) {
  let newarry = [];
  let startind = 0;
  let numtograb = 0;
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
  let len = result.length;
  const searchStatus = document.getElementById("ptx-search-status");
  if (len == 0) {
    document.getElementById("ptx-search-empty").style.display = "block";
    document.getElementById("ptx-search-dialog").style.display = null;
    searchStatus.innerHTML = window.i18next.t('No results found for "{{terms}}".', { terms: searchterms });
    return;
  }
  document.getElementById("ptx-search-empty").style.display = "none";
  searchStatus.innerHTML = window.i18next.t("{{count}} results found.", { count: len });
  let allScores = result.map(function(r) {
    return r.score;
  });
  allScores.sort((a, b) => a - b);
  allScores.reverse();
  let high = allScores[Math.floor(len * 0.2)];
  let med = allScores[Math.floor(len * 0.4)];
  let low = allScores[Math.floor(len * 0.75)];
  if (ptx_lunr_search_style == "reference") {
    result = rearrangedArray(result);
  }
  let indent = "1";
  let currIndent = indent;
  let origResult = resultArea;
  for (const res of result) {
    let link = document.createElement("a");
    if (res.score >= high) {
      link.classList.add("ptx-search-result-high");
    } else if (res.score >= med) {
      link.classList.add("ptx-search-result-medium");
    } else if (res.score >= low) {
      link.classList.add("ptx-search-result-low");
    } else {
      link.classList.add("ptx-search-result-none");
    }
    currIndent = res.level;
    if (currIndent > indent) {
      indent = currIndent;
      let ilist = document.createElement("ul");
      ilist.classList.add("ptx-search-detailed-result");
      resultArea.appendChild(ilist);
      resultArea = ilist;
    } else if (currIndent < indent) {
      resultArea = origResult;
      indent = currIndent;
    }
    link.href = `${res.url}`;
    link.innerHTML = `${res.type} ${res.number} ${res.title}`;
    let clip = document.createElement("div");
    clip.classList.add("ptx-search-result-clip");
    clip.innerHTML = `${res.body}`;
    let bullet = document.createElement("li");
    bullet.classList.add("ptx-search-result-bullet");
    bullet.appendChild(link);
    bullet.appendChild(clip);
    let p = document.createElement("text");
    p.classList.add("ptx-search-result-score");
    p.innerHTML = `  (${res.score.toFixed(2)})`;
    bullet.appendChild(p);
    resultArea.appendChild(bullet);
  }
  const resultsDialog = document.getElementById("ptx-search-dialog");
  resultArea.querySelectorAll("a").forEach((link) => {
    link.addEventListener("click", (e) => {
      resultsDialog.close();
    });
  });
  document.getElementById("ptx-search-dialog").style.display = null;
  MathJax.typesetPromise();
}
window.addEventListener("load", function(event) {
  const searchDialogElement = document.getElementById("ptx-search-dialog");
  const searchButtonElement = document.getElementById("ptx-search-button");
  const closeBtn = document.getElementById("ptx-search-close");
  const searchDialog = new PTXDialog(searchDialogElement, searchButtonElement, {
    closeButton: closeBtn
  });
  searchButtonElement.addEventListener("click", (e) => {
    const lastSearch = localStorage.getItem("last-search-terms");
    let searchInput = document.getElementById("ptx-search-terms");
    searchInput.value = lastSearch ? JSON.parse(lastSearch)?.terms || "" : "";
    searchInput.select();
    if (searchInput.value) {
      doSearch();
    }
  });
  document.getElementById("ptx-search-terms").addEventListener("input", (e) => {
    doSearch();
  });
});
//# sourceMappingURL=pretext_search.js.map
