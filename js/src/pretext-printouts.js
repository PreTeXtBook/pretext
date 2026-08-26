/*******************************************************************************
 * pretext-printouts.js
 *******************************************************************************
 * Logic for HTML print previews: paginating a worksheet/handout (or a
 * project-like standalone printout) into `.onepage` sections, fitting
 * workspace (blank writing space) to the page, headers/footers, footnotes,
 * and the hide-hint/answer/solution controls used on the print preview page.
 *
 * Split out of pretext_add_on.js so this large, self-contained subsystem has
 * its own file. Bundled into pretext-core.js by jsbuilder.mjs; see js/src/pretext-core.js.
 *
 * Homepage: pretextbook.org
 * Repository: https://github.com/PreTeXtBook/JS_core
 ******************************************************************************/

// The new method for creating pages and adjusting workspace //

// The element being previewed.  Usually a worksheet or handout section, but a
// project-like block with workspace that lives outside any worksheet/handout
// is previewed as a printout in its own right, in which case this is the
// project's <article>.  loadPrintout() tags whichever it is with "printout",
// which is also the hook the print stylesheet keys on, so nothing downstream
// has to care which kind of element it got.
function getPrintout() {
    return document.querySelector('.printout');
}

// Unwrap section.paragraphs containers so their children flow directly
// into the parent, enabling CSS page breaks between the inner elements.
function flattenParagraphsSections(printout) {
    const paragraphsSections = printout.querySelectorAll('section.paragraphs');
    paragraphsSections.forEach(section => {
        const parent = section.parentNode;
        // Move all children out of the section wrapper and into the parent
        while (section.firstChild) {
            parent.insertBefore(section.firstChild, section);
        }
        // Remove the now-empty section wrapper
        parent.removeChild(section);
    });
}

// Wait for all images inside a container to finish loading.
// Returns a promise that resolves when every <img> has loaded (or on timeout).
function waitForImages(container, timeoutMs = 5000) {
    const images = container.querySelectorAll('img');
    const promises = [];
    for (const img of images) {
        if (!img.complete) {
            promises.push(new Promise(resolve => {
                img.addEventListener('load', resolve, { once: true });
                img.addEventListener('error', resolve, { once: true });
            }));
        }
    }
    if (promises.length === 0) return Promise.resolve();
    // Race all image loads against a timeout so broken images don't block forever
    return Promise.race([
        Promise.all(promises),
        new Promise(resolve => setTimeout(resolve, timeoutMs))
    ]);
}

// Moving a row between .onepage containers makes any <iframe> inside it
// (e.g. a YouTube video or GeoGebra applet) reload, even when it lands back
// in the same parent.  A single settle loop (repagination/spillover-collapse
// running repeatedly until layout stabilizes) can move a row several times,
// so detach every iframe -- swapped for a same-sized placeholder, to keep
// height measurements accurate -- before a batch of repagination work and
// reattach afterward, capping each toggle at reloading a video once instead
// of once per move.
async function withIframesDetached(fn) {
    const printout = getPrintout();
    const parked = [];
    if (printout) {
        printout.querySelectorAll('iframe').forEach(iframe => {
            const rect = iframe.getBoundingClientRect();
            const placeholder = document.createElement('div');
            placeholder.className = 'iframe-placeholder';
            placeholder.style.width = rect.width + 'px';
            placeholder.style.height = rect.height + 'px';
            placeholder.style.display = getComputedStyle(iframe).display;
            iframe.parentNode.insertBefore(placeholder, iframe);
            iframe.remove();
            parked.push({iframe, placeholder});
        });
    }
    try {
        return await fn();
    } finally {
        parked.forEach(({iframe, placeholder}) => {
            placeholder.parentNode.insertBefore(iframe, placeholder);
            placeholder.remove();
        });
    }
}

// The workspace divs in, or at, an element.  In a worksheet a workspace is
// always nested inside an exercise or task, but a project-like standalone
// printout can carry @workspace on itself, and then the block *is* the
// workspace div -- which querySelectorAll, looking only at descendants, misses.
// Whether a top-level row *is* blank writing space, in either of the two
// shapes it can take.  The "highlight workspace" overlay wraps every
// `.workspace` in a `.workspace-container` (see toggleWorkspaceHighlight()),
// and since flattenSolutionsIn() has by then made the workspace a row in its
// own right, that wrapper becomes the row.  The wrapper carries neither the
// `workspace` class nor the group stamp, so testing for `.workspace` alone
// means every workspace rule below -- never opening a page with writing
// space, keeping a question with its own workspace, suppressing a stranded
// one -- silently stops applying the moment the reader ticks that checkbox.
function isWorkspaceRow(elem) {
    return elem.classList.contains('workspace') || elem.classList.contains('workspace-container');
}

// A workspace row that is *actually* blank writing space on the page.  Both
// pagination paths refuse to open a page with writing space -- findPageBreaks()
// when it plans from scratch, addSpilloverPages() when it splits at runtime --
// because a slab of empty space above the question it belongs to reads as a
// mistake.  A row suppressed by hideWidowedWorkspaces() carries `hidden` and
// occupies nothing, so there is no slab to protect the reader from, and
// applying the rule to it only retreats to an earlier break and pushes real
// content onto a later page to make room for something invisible.
function isVisibleWorkspaceRow(elem) {
    return isWorkspaceRow(elem) && !elem.classList.contains('hidden');
}

function workspaceDivsIn(elem) {
    if (elem.classList.contains('workspace')) {
        return [elem];
    }
    return [...elem.querySelectorAll('.workspace')];
}

// Split .task (and .conclusion) elements out of an .exercise -- or out of an
// enclosing .task, for sub-tasks -- so each becomes its own top-level child
// of `container`, positioned immediately after the block that used to hold
// it. This is what lets both pagination paths treat a single task as an
// independently placeable/movable unit: for computed pagination it lets
// findPageBreaks() weigh each task on its own, and for authored pagination
// it lets addSpilloverPages() push just the oversized task (and whatever
// follows it on that page) onto a spillover page, instead of being stuck
// with the whole exercise as one atomic block that can't be split when a
// solution inside it grows too long.
function flattenTasksIn(container) {
    for (const child of [...container.children]) {
        if (child.classList.contains('sidebyside')) {
            continue; // sidebyside could have tasks, but we don't split into it
        }
        // A sidebyside nested deeper than `child` itself (e.g. a diagram next
        // to a task's text) is excluded the same way: its tasks stay put.
        const tasks = [...child.querySelectorAll('.task, .conclusion')].filter(el => !el.closest('.sidebyside'));
        if (tasks.length === 0) continue;
        // Tag nesting depth so CSS can indent appropriately once an element
        // is pulled out of its parent .task/.exercise: if its parent (or
        // grandparent) is itself a .task, it was a sub-(sub-)task.
        for (const task of tasks) {
            const parent = task.parentElement;
            const grandparent = parent.parentElement;
            if (grandparent && grandparent.classList.contains('task')) {
                task.classList.add('subsubtask');
            } else if (parent.classList.contains('task')) {
                task.classList.add('subtask');
            }
        }
        // Move every task out, including the first one, in reverse order, so
        // they land in their original order immediately after `child`.
        for (let i = tasks.length - 1; i >= 0; i--) {
            container.insertBefore(tasks[i], child.nextSibling);
        }
    }
}

// Split a long `.introduction` block up so its paragraphs/tables/etc. become
// independent top-level children of `container`, the same way flattenTasksIn
// splits out `.task`/`.conclusion`. Otherwise an introduction is one atomic
// row for pagination purposes, and overflows the page whenever it alone is
// taller than a page, regardless of how the task(s) after it are split.
//
// The print stylesheet displays a heading inline with its first paragraph
// (`article>.heading:first-child+:is(.para,.para.logical,.introduction)`),
// so the introduction's first child is left in place -- replacing the
// .introduction wrapper right where it was -- rather than extracted, and
// only the rest is moved out to become independent top-level rows.
//
// Must run after flattenTasksIn(), since the reverse insertion here also
// targets `child.nextSibling`, and running after keeps reading order correct
// (introduction paragraphs end up before the task, not after it).
//
// A `.introduction` can appear nested inside a top-level child (e.g. an
// exercise's own introduction) or as a top-level child itself (e.g. a
// project-like printout's own opening section). Both are handled: for the
// nested case the wrapper is unwrapped in place and its later children
// extracted to be `child`'s top-level siblings; for the top-level case the
// wrapper *is* `child`, so the first paragraph becomes the new top-level row
// in its place, and later children are extracted as its siblings instead.
function flattenIntroductionsIn(container) {
    for (const child of [...container.children]) {
        if (child.classList.contains('sidebyside')) {
            continue; // sidebyside could have introductions, but we don't split into it
        }
        const isTopLevelIntroduction = child.classList.contains('introduction');
        // A sidebyside nested deeper than `child` itself (e.g. a project
        // description next to a figure) is excluded the same way as above:
        // its introduction stays put.
        const introductions = isTopLevelIntroduction
            ? [child]
            : [...child.querySelectorAll('.introduction')].filter(intro => !intro.closest('.sidebyside'));
        // Where the next introduction's extracted content gets inserted.
        // Starts at `child` and advances to the last row placed by each
        // introduction in turn, so that when `child` contains more than one
        // (e.g. an exercisegroup whose member exercises each carry their own),
        // a later introduction's paragraphs land after an earlier one's
        // instead of before it -- inserting every one of them relative to the
        // same fixed `child` would put the last-processed introduction first.
        let insertionAnchor = child;
        introductions.forEach(intro => {
            const introParent = intro.parentNode;
            const introChildren = [...intro.children];
            if (introChildren.length === 0) {
                intro.remove();
                return;
            }
            // Leave the first paragraph in place, right where .introduction was,
            // so it stays adjacent to whatever precedes it (typically the heading).
            introParent.insertBefore(introChildren[0], intro);
            // When `intro` was itself the top-level child, `child` no longer
            // occupies a slot in `container` -- the first paragraph just placed
            // above does instead -- so anchor off that rather than insertionAnchor.
            const anchor = intro === child ? introChildren[0] : insertionAnchor;
            for (let i = introChildren.length - 1; i >= 1; i--) {
                container.insertBefore(introChildren[i], anchor.nextSibling);
            }
            intro.remove();
            insertionAnchor = introChildren[introChildren.length - 1];
        });
    }
}

// The classes flattenTasksIn() and flattenSolutionsIn() stamp on a row before
// hoisting it, so the print stylesheet can re-create the indentation the hoist
// destroys.  Ordered shallowest first.
const DEPTH_CLASSES = ['subtask', 'subsubtask', 'subsubsubtask'];

// The depth class a row hoisted out of `owner` needs to keep lining up with
// it.  Read off `owner`'s own classes rather than its ancestry: flattenTasksIn()
// has already run, so the nesting that would have said how deep `owner` sat is
// gone, and the class it stamped on the way out is the only record left.
//
// The names mean the same thing here as they do there -- "subtask" is "I came
// out of a task" -- so a row out of a plain task takes `subtask`, one out of a
// task that was itself a subtask takes `subsubtask`, and so on.  A row belongs
// at its owner's own level, not one step further in, exactly as a `.conclusion`
// does; the print stylesheet is what turns that into the matching margin.
function depthClassForRowOut(owner) {
    if (owner.classList.contains('subsubtask')) return 'subsubsubtask';
    if (owner.classList.contains('subtask')) return 'subsubtask';
    if (owner.classList.contains('task')) return 'subtask';
    return null;
}

// Move whichever depth class `from` carries onto `to`.  Used when the
// "highlight workspace" overlay wraps a workspace, since the wrapper then
// stands in as the row: the indent has to move with that role.  A margin left
// on the workspace itself would not do -- it is `width: 100%` of the wrapper,
// so a margin widens it past the wrapper's right edge instead of shifting it
// over, and with both elements carrying the class the indent would double.
function moveDepthClass(from, to) {
    for (const cls of DEPTH_CLASSES) {
        if (from.classList.contains(cls)) {
            from.classList.remove(cls);
            to.classList.add(cls);
        }
    }
}

// Serial number behind the `data-block-group` stamps below.  Module-level and
// monotonic, deliberately: an id has to be unique among every row that could
// ever share a page, and a counter local to the call does not achieve that.
// adjustPrintoutPages() runs flattenSolutionsIn() once per authored page, so a
// call-local counter hands every page its own `bg-0` -- and hideWidowedWorkspaces(),
// which decides whether a workspace still has its question by looking that id
// up among the page's rows, would accept a completely unrelated group's
// question as the answer if two such pages were ever merged onto one.  Nothing
// merges them today (a full recompute only runs when there are no authored
// pages, and collapseSpilloverPages() folds a spillover page back only into
// the page it was split from), but nothing declares that they cannot be.
//
// Surviving a repagination costs nothing, because the ids are meant to persist
// anyway: a second createPrintoutPages() finds the `.solutions` wrappers
// already consumed by the first pass, reissues nothing, and the stamps left
// behind by that first pass are what keep the groups intact.  It is the
// stamping *not* being redone that makes the scheme work.
let blockGroupSeq = 0;

// Split a `.solutions` block up so each hint/answer/solution knowl becomes
// an independent top-level row, the same way flattenTasksIn splits out
// `.task` and flattenIntroductionsIn splits out `.introduction`. Otherwise
// a task or exercise with a large solution is one atomic row that overflows
// the page whenever its prompt plus its solution content together are
// taller than a page, even if the prompt alone would fit comfortably.
//
// Unlike `.introduction`, `.solutions` has no adjacent-heading display rule
// to preserve, so every child is extracted -- none needs to stay behind.
//
// Must run after flattenTasksIn() so that, when the `.solutions` belongs to
// a task rather than directly to an exercise, `child` is already that task
// (a top-level row in its own right) -- keeping the extracted solution
// content ordered right after its own task instead of after a sibling task.
//
// The block's `.workspace` is hoisted out along with the solutions, and
// lands after them.  The XSL emits an exercise as statement, then
// `div.solutions`, then `div.workspace` (the workspace is applied after
// "wrapped-content" and so is the block's last real child).  Extracting only
// the solutions would leave the workspace behind *inside* the block, which
// renders it before the rows just hoisted out -- so a revealed hint or
// solution would appear below a slab of blank writing space instead of
// directly under its question.  Moving the workspace out too, after the
// solution rows, restores the authored reading order and makes the blank
// space an independently placeable row like every other.
//
// Rows split out of one block are stamped with a shared `data-block-group`
// so pagination can try to keep a question with its solutions and workspace
// (see findPageBreaks(), which will not start a page with a workspace row,
// and hideWidowedWorkspaces(), which suppresses writing space stranded away
// from its question).
function flattenSolutionsIn(container) {
    for (const child of [...container.children]) {
        if (child.classList.contains('sidebyside') || child.classList.contains('solutions')) {
            continue;
        }
        // Nested sidebyside excluded, same reasoning as flattenTasksIn/
        // flattenIntroductionsIn.
        const solutionsBlocks = [...child.querySelectorAll('.solutions')].filter(solutions => !solutions.closest('.sidebyside'));
        // Advances after each block, same reasoning as flattenIntroductionsIn:
        // when `child` has more than one solutions block (e.g. an
        // exercisegroup whose member exercises each have their own), a later
        // block's content must land after an earlier block's, not before it.
        let insertionAnchor = child;
        solutionsBlocks.forEach(solutions => {
            // Captured before the block is removed below.  This is the
            // exercise or task the solutions belong to -- after
            // flattenTasksIn() that is usually `child` itself, but for an
            // exercisegroup `child` holds several such owners, each with
            // its own solutions and its own workspace to keep together.
            const owner = solutions.parentElement;
            // Captured for the same reason, and before the rows move for the
            // same reason: once they are top-level children of `container`
            // nothing about them says they came out of a task.  See
            // depthClassForRowOut().
            const depthClass = depthClassForRowOut(owner);
            const group = `bg-${blockGroupSeq++}`;
            const solChildren = [...solutions.children];
            for (let i = solChildren.length - 1; i >= 0; i--) {
                container.insertBefore(solChildren[i], insertionAnchor.nextSibling);
                if (depthClass) {
                    solChildren[i].classList.add(depthClass);
                }
            }
            solutions.remove();
            if (solChildren.length > 0) {
                insertionAnchor = solChildren[solChildren.length - 1];
            }
            // Follow the solutions out, so reading order stays
            // statement -> hint/answer/solution -> blank writing space.
            const workspace = owner.querySelector(':scope > .workspace');
            if (workspace) {
                container.insertBefore(workspace, insertionAnchor.nextSibling);
                // Indented along with them: a task's writing space is only
                // hoisted when that task has solutions, so leaving it flush
                // left would set it apart from the workspace of every sibling
                // task that has none and so stayed put, indented, inside.
                if (depthClass) {
                    workspace.classList.add(depthClass);
                }
                insertionAnchor = workspace;
            }
            // Tag the whole set, including the question row that stayed put,
            // so the group can be kept together (or deliberately broken)
            // later.  When `owner` is nested deeper than `child` (the
            // exercisegroup case) the question row is the whole group and
            // is shared by several owners, so it is left untagged rather
            // than bound to whichever owner happened to be processed last.
            const questionRow = owner === child ? child : null;
            const anchors = [questionRow, ...solChildren].filter(el => el && el.parentElement === container);
            // A group needs at least one row that is not the workspace for it
            // to be anchored to; otherwise (an empty `.solutions` inside an
            // exercisegroup, say) hideWidowedWorkspaces() would find no
            // question on the page and suppress perfectly good writing space.
            if (anchors.length === 0) return;
            for (const el of [...anchors, workspace]) {
                if (el && el.parentElement === container) {
                    el.dataset.blockGroup = group;
                }
            }
        });
    }
}

// This is used multiple places to set height of workspace divs to their author-provided heights
function setInitialWorkspaceHeights() {
    const workspaces = document.querySelectorAll('.workspace');
    workspaces.forEach(ws => {
        ws.style.height = ws.getAttribute('data-space') || '0px';
        ws.setAttribute("contenteditable", "true");
    });
}

// If a printout (worksheet or handout) includes authored pages, we only need to put content before the first page and after the last page into the first and last pages, respectively.
function adjustPrintoutPages(margins) {
    console.log("*** Adjusting printout pages.");
    const printout = getPrintout();
    if (!printout) {
        console.warn("No printout found, exiting adjustPrintoutPages.");
        return;
    }
    const pages = printout.querySelectorAll('.onepage');
    if (pages.length === 0) {
        console.warn("No pages found in printout, exiting adjustPrintoutPages.");
        return;
    }
    // Find all children before the first .onepage element:
    const firstPage = pages[0];
    const lastPage = pages[pages.length - 1];
    // Move all children before the first page into the first page
    const pageFirstChild = firstPage.firstChild;
    let currentChild = printout.firstChild;
    while (currentChild && currentChild !== firstPage) {
        const nextChild = currentChild.nextSibling; // Save the next sibling before removing
        firstPage.insertBefore(currentChild, pageFirstChild); // Move to the first page
        currentChild = nextChild; // Move to the next child
    }
    // Now find all children after the last .onepage element:
    let nextChild = lastPage.nextSibling;
    while (nextChild) {
        const tempChild = nextChild;
        nextChild = nextChild.nextSibling;
        lastPage.appendChild(tempChild);
    }
    // Split nested tasks out to be top-level children of their page (see
    // flattenTasksIn), so overflowing solutions inside a single task can be
    // spilled onto a new page instead of dragging the whole exercise along
    // as one unsplittable block. Then do the same for introductions (see
    // flattenIntroductionsIn); must run second so reading order stays correct.
    // The authored pages are real page boxes already, so a row too tall for one
    // is measured against the same budget a computed page is planned against.
    const contentHeight = 1056 - (margins.top + margins.bottom);
    pages.forEach(page => {
        flattenTasksIn(page);
        flattenIntroductionsIn(page);
        flattenSolutionsIn(page);
        // Last, so it sees the rows the three above have just made: a list
        // inside a task only becomes splittable once that task is a row.
        // Nothing here re-plans the page breaks -- the author fixed those --
        // so the gain is that addSpilloverPages() can push part of an
        // over-long list onto a spillover page instead of being handed one
        // unsplittable row and giving up on it.
        flattenOversizedListsIn(page, contentHeight);
    });
    console.log("Moved all content before the first page and after the last page into the respective pages, and split nested tasks, introductions, solutions, and oversized lists for independent repagination.");
}

// This is the main function we will call then a printout does not come from the XSL with pages already defined (for now, the XSL will keep the <page> behavior as an option).
function createPrintoutPages(margins) {
    console.log("*** Creating printout pages with margins:", margins);

    // Assumptions: needs to work for both letter (8.5in x 11in) and a4 (210mm x 297mm) paper sizes.  We will work in pixels (96/in): those are 816px x 1056px and 794px x 1122.5px respectively (1 inch = 96 px, 1 cm = 37.8 px).  We assume that the printing interface of the browser will do the right thing with these.

    // For purposes of finding page breaks, we will use 794 as our width and 1056 as our height (so A4 width and letter height).  Then we will rescale workspace on each page to fit the actual paper size selected.

    // The paper a plan is made against: A4's width and Letter's height, the
    // narrower and the shorter of the two, so that a plan made here holds on
    // either.  The content box is what is left of that once the print margins
    // are taken off.
    const conservativePaperWidth = 794;   // A4 is narrower than Letter's 816
    const conservativeContentHeight = 1056 - (margins.top + margins.bottom); // in pixels
    const conservativeContentWidth = conservativePaperWidth - (margins.left + margins.right); // in pixels

    const printout = getPrintout();
    if (!printout) {
        console.warn("No printout found, exiting createPrintoutPages.");
        return;
    }
    // Narrow the printout to our conservative paper width while we measure row
    // heights below, so text wraps at least as much as it will once placed in
    // the real .onepage box -- otherwise rows measure shorter than their
    // actual rendered height and pagination overflows.
    //
    // The *paper* width, not the content width.  A `.onepage` is `border-box`
    // and pads itself by the print margins, so it takes its content width from
    // the paper width by subtracting them itself; handing it a width that has
    // already had them taken off subtracts them twice.  That is not merely
    // conservative, it is wrong by a wide margin -- at 0.75in margins the rows
    // were measured in a 506px column and then laid out in a 672px one -- and
    // since every row measures taller than it renders, each page was planned
    // full and came out a third empty.  The error scales with how many rows a
    // page holds, so it went unnoticed while rows were whole exercises and
    // became glaring as soon as an over-long list was cut into one row per
    // item (see flattenOversizedListsIn()).
    printout.style.width = conservativePaperWidth + 'px';
    // Set the height of each workspace based on its data-space attribute
    setInitialWorkspaceHeights(printout);

    // We want to consider each "block" of the printout.  Some of these will be direct children of the printout, some will be nested inside these children (e.g. tasks inside an exercise).  Split those out into their own top-level blocks first (see flattenTasksIn), then every block we care about is simply a direct child of the printout.
    // Skipping separate treatment of exercisegroups for now.
    flattenTasksIn(printout);
    // Same treatment for introductions (see flattenIntroductionsIn) and for
    // task solutions (see flattenSolutionsIn); both must run after
    // flattenTasksIn so reading order comes out right.
    flattenIntroductionsIn(printout);
    flattenSolutionsIn(printout);
    let rows = [...printout.children];
    // Measure the rows in the context they will actually be rendered in.
    //
    // The print stylesheet scopes a good deal to `.onepage` -- most sharply
    // `.onepage .instructions { display: none }`, which suppresses tool chrome
    // such as diagcess's "Diagram Exploration Keyboard Controls" panel. Taking
    // heights while the rows are still children of the printout means none of
    // those rules are in force, so such a row measures as real content, is
    // given space in the page-break plan, and then renders as nothing once it
    // lands in a `.onepage` -- which is how a worksheet ends up with a
    // completely blank sheet in the middle of it.
    //
    // So park the rows in a throwaway `.onepage` for the duration of the
    // measuring loop. Its width is pinned to the conservative paper width for
    // the same reason the printout's was, and in the same units: this element
    // carries the real `.onepage` padding, so it is the paper width that leaves
    // it the content width the rows will really be laid out in.
    const measuringPage = document.createElement('section');
    measuringPage.classList.add('onepage');
    measuringPage.style.width = conservativePaperWidth + 'px';
    // The real page box is a fixed height; this one has to grow with whatever
    // it holds, or every row past the first page's worth would measure clipped.
    measuringPage.style.height = 'auto';
    printout.appendChild(measuringPage);
    rows.forEach(row => measuringPage.appendChild(row));
    // A row that is taller than a page cannot be placed whole, and gets clipped
    // rather than broken.  Now that the rows are parked where their real
    // rendered heights can be read, cut up the lists inside any such row so
    // there is something for a page break to fall between -- and re-read the
    // rows, since doing so replaces one of them with several.
    if (flattenOversizedListsIn(measuringPage, conservativeContentHeight)) {
        rows = [...measuringPage.children];
    }
    // Measure the footnote block here too, while the rows are parked in the
    // same scaffold, for the same reason: it has to wrap at the real page width
    // and under the rules that only apply inside a .onepage.
    const footnoteMetrics = measureFootnotes(rows, measuringPage);
    // Loop through the blocks and create a list of objects including the block, its height, and its workspace height.  Only include blocks that have height (this will remove autopermalinks, as desired).
    let blockList = [];
    for (const row of rows) {
        let blockHeight = getElementTotalHeight(row);
        // A currently-hidden hint/answer/solution row also measures zero
        // height, but unlike an autopermalink it's meaningful content that
        // may be revealed later -- it still needs a page to call home. Rows
        // never added to blockList never get moved into a .onepage below,
        // and then get deleted outright by the "remove old content not in a
        // page" cleanup at the end of this function, which is correct for a
        // genuinely-empty row but was silently destroying hidden solution
        // content (and, since printout.children is a live collection there,
        // corrupting the position of whatever survived that by accident).
        // Keeping it in blockList with height 0 costs nothing towards
        // findPageBreaks()'s page-height budget -- it just rides along onto
        // whichever page its neighbors land on, ready to be revealed in place.
        // Tested against the row's own rendered box rather than blockHeight,
        // which adds the margins on: an autopermalink has no box at all
        // (offsetHeight 0) but does carry vertical margin, so measured the
        // margin-inclusive way it looks like a ~22px row and survives this
        // filter -- defeating the "remove autopermalinks" intent above. It
        // then goes on to claim a page of its own whenever its neighbour is a
        // block too tall to share with (findPageBreaks() gives such a block a
        // page to itself), and the reader gets a completely blank sheet.
        if (row.offsetHeight === 0 && !row.classList.contains('hidden')) {
            console.log("Skipping row with zero height:", row);
            continue;
        }
        let totalWorkspaceHeight = 0;
        if (workspaceDivsIn(row).length > 0) {
            // Workspace height is not just sum of workspace heights; we need to be careful with sidebyside and columns
            totalWorkspaceHeight = getElemWorkspaceHeight(row);
        }
        blockList.push({
            elem: row,
            height: blockHeight,
            workspaceHeight: totalWorkspaceHeight,
            // Set by flattenSolutionsIn() on the rows split out of a single
            // exercise or task, so findPageBreaks() can tell which rows want
            // to stay together on one page.  Undefined for rows that were
            // never split out of anything.
            group: row.dataset.blockGroup,
            // A row that *is* a hoisted workspace, as opposed to one that
            // merely contains a workspace nested inside it.  Such a row is
            // pure blank writing space, so it must never be what a page
            // opens with -- see findPageBreaks().  Suppressed writing space
            // does not count; see isVisibleWorkspaceRow().
            isWorkspace: isVisibleWorkspaceRow(row),
            // How much room this row's own footnotes will take at the foot of
            // whichever page it lands on.  Charged to the row rather than to
            // the page because that is what makes the cost move with the row:
            // the DP in findPageBreaks() then accumulates it over exactly the
            // rows a candidate page holds, with no circularity to resolve.
            footnoteHeight: footnoteMetrics.heights.get(row) || 0,
        });
    }

    // Done measuring: return the rows to the printout and drop the scaffold,
    // so the page-building loop below distributes them as it always has.
    rows.forEach(row => printout.appendChild(row));
    measuringPage.remove();

    // Now find pageBreaks so that extra workspace is as uniform as possible.
    // Squeezing blank writing space below its authored height is only on the
    // table once something is revealed that needs the room (see pageCost()).
    const pageBreaks = findPageBreaks(blockList, conservativeContentHeight, {
        allowSqueeze: anySolutionShown(),
        footnoteChrome: footnoteMetrics.chrome,
    });

    // Done measuring; let the printout go back to its normal width so the
    // .onepage sections built below render at their real page size.
    printout.style.width = "";

    // Create page divs and insert rows into them
    for (let i = 0; i < pageBreaks.length; i++) {
        const pageDiv = document.createElement('section');
        pageDiv.classList.add('onepage');
        if (i === 0) {
            pageDiv.classList.add('firstpage');
        }
        // A single page will be both first and last
        if (i === pageBreaks.length - 1) {
            pageDiv.classList.add('lastpage');
        }
        // The pageBreaks array gives the indices of blocks that should start a page.
        // So we will want to look for go through the blocks selecting those starting with the previous index (or 0) up to but not including the current index.
        const start = pageBreaks[i-1] || 0;
        const end = pageBreaks[i];
        for (let j = start; j < end; j++) {
            const row = blockList[j].elem;
            pageDiv.appendChild(row);
        }
        printout.appendChild(pageDiv);
    }

    // remove any old content that is not in a page
    // Snapshot the children first: `printout.children` is a live collection,
    // so removing through its own iterator shifts every later element down one
    // and skips the next candidate.  A row that survives this loop by accident
    // is left outside every page -- and now that rows carry group stamps that
    // pagination relies on, one going missing takes its group's cohesion with
    // it.
    for (const child of [...printout.children]) {
        if (!child.classList.contains('onepage')) {
            console.log("Removing old child not in a page:", child);
            printout.removeChild(child);
        }
    }
}

function getPageContentBottom(page) {
    // The page element's own bottom edge includes its bottom padding, which
    // corresponds to the print margin. Content that lands in that padding
    // area still fits within the page's outer box, but real printing
    // respects the margin strictly and will push it to the next page.
    // So overflow must be measured against the content area, not the raw box.
    const pRect = page.getBoundingClientRect();
    const paddingBottom = parseFloat(getComputedStyle(page).paddingBottom) || 0;
    return pRect.bottom - paddingBottom;
}

function pageOverflows() {
    const pages = document.querySelectorAll('.onepage');
    for (const page of pages) {
        for (const child of page.children) {
            const r = child.getBoundingClientRect();
            if (r.bottom > getPageContentBottom(page) + 1) {
                return true;
            }
        }
    }
    return false;
}

// Blank writing space only means something directly beneath the question it
// was authored for.  findPageBreaks() will not plan a page that opens with a
// workspace row, but a group can still be pulled apart afterwards -- most
// often by addSpilloverPages(), which pushes whatever overflows onto a fresh
// page at runtime.  When that leaves a workspace on a page without the
// question it belongs to, a slab of blank space with no prompt above it is
// worse than no writing space at all, so it is suppressed.
//
// Hidden rather than removed, and recomputed from scratch on every call, so
// that a later toggle which brings the group back onto one page brings the
// writing space back with it.  Suppressing a workspace only ever frees
// vertical space, so this can never introduce a new overflow.
// Only applies while something is revealed, for the same reason pageCost()
// will not squeeze: with nothing shown, the authored writing space is what the
// reader is meant to get, and suppressing it would quietly take that away.
//
// Suppression is the `hidden` class, not an inline `display`, and every pass
// clears it from every workspace and wrapper in the printout before deciding
// again.  Clearing everything first is what makes "recomputed from scratch"
// above actually true: a workspace is the row only until the reader ticks
// "highlight workspace", after which toggleWorkspaceHighlight() wraps it and
// the `.workspace-container` is the row instead (see isWorkspaceRow()).
// Writing only to whichever element holds that role at the time leaves the
// suppression stranded on the other one -- hide a workspace while unwrapped,
// tick the box, and un-hiding restores the container while the `.workspace`
// inside it stays suppressed for the rest of the session.
//
// The class rather than an inline style because createPrintoutPages() skips
// zero-height rows and then deletes whatever never landed in a `.onepage`,
// exempting only `.hidden`.  A workspace suppressed with `display:none`
// measures zero, carries no such exemption, and would be destroyed outright
// by the next full recompute instead of restored by it.  Nothing reaches that
// today -- every recompute is chained ahead of the first reveal, so nothing is
// ever suppressed while one runs -- but that is an accident of ordering, not
// an invariant.  `.hidden` also measures 0 in getElemWorkspaceHeight(), which
// reads offsetHeight, so pagination correctly stops reserving room for writing
// space the reader cannot see.
function hideWidowedWorkspaces() {
    const printout = getPrintout();
    if (!printout) return;
    const stranding = anySolutionShown();
    // Start from a clean slate, so no earlier pass's decision can survive on an
    // element that is no longer the row.  Safe to own the class outright here:
    // nothing else in the printout ever hides a workspace -- solutions and
    // headers/footers carry `hidden` on their own elements.
    printout.querySelectorAll('.workspace, .workspace-container').forEach(ws => ws.classList.remove('hidden'));
    printout.querySelectorAll(':scope > .onepage').forEach(page => {
        const rows = [...page.children].filter(c => !isPageFurnitureEl(c));
        const questionGroupsOnPage = new Set(
            rows.filter(r => !isWorkspaceRow(r))
                .map(r => r.dataset.blockGroup)
                .filter(Boolean)
        );
        for (const row of rows) {
            if (!isWorkspaceRow(row) || !row.dataset.blockGroup) continue;
            if (stranding && !questionGroupsOnPage.has(row.dataset.blockGroup)) {
                console.log("Hiding workspace stranded from its question:", row);
                row.classList.add('hidden');
            }
        }
    });
}

function adjustWorkspaceOrRepaginate({paperSize, margins, fullRecompute = false}) {
    adjustWorkspaceToFitPage({paperSize, margins});
    if (pageOverflows()) {
        if (fullRecompute) {
            resetPrintoutPagination(margins);
        } else {
            addSpilloverPages(margins);
        }
        adjustWorkspaceToFitPage({paperSize, margins});
    }
    // After the layout has settled, drop writing space that ended up separated
    // from its question by whichever repagination path ran above.
    hideWidowedWorkspaces();
}

function unwrapOnepages() {
    const printout = getPrintout();
    if (!printout) return;
    const pages = [...printout.querySelectorAll(':scope > .onepage')];
    pages.forEach(page => {
        [...page.children].filter(isPageFurnitureEl).forEach(el => el.remove());
        while (page.firstChild) {
            printout.insertBefore(page.firstChild, page);
        }
        printout.removeChild(page);
    });
}

function resetPrintoutPagination(margins) {
    unwrapOnepages();
    createPrintoutPages(margins);
    addHeadersAndFootersToPrintout();
}

// Furniture that trails a page's content: the block of collected footnote text
// and the footer band, in that order.
function isPageTailEl(el) {
  return el.classList.contains('footnotes') ||
         el.classList.contains('first-page-footer') || el.classList.contains('running-footer');
}

// Everything a page carries that is not authored content: the header band, and
// the tail furniture above.  None of it is a movable row -- it is a property of
// whatever content ends up on the page, not content in its own right -- so
// pagination must never push it onto a spillover page or merge it into a
// previous one.  All of it is destroyed and rebuilt from scratch by
// addHeadersAndFootersToPrintout() after every repagination.
function isPageFurnitureEl(el) {
  return el.classList.contains('first-page-header') || el.classList.contains('running-header') ||
         isPageTailEl(el);
}

function addSpilloverPages(margins) {
  const printout = getPrintout();
  if (!printout) return;
  // Drop any bottom-anchoring offset before measuring.  adjustWorkspaceToFitPage()
  // grows a footnote block's top margin to push it to the foot of a page that
  // has room to spare; that padding is slack, not content, and reserving room
  // for it below would split a page that already fits.  The blocks are torn
  // down and rebuilt at the end of this function anyway.
  printout.querySelectorAll(':scope > .onepage > .footnotes').forEach(block => {
    block.style.marginTop = "";
  });
  let pages = [...printout.querySelectorAll(':scope > .onepage')];

  for (let i = 0; i < pages.length; i++) {
    const page = pages[i];
    const contentChildren = [...page.children].filter(c => !isPageFurnitureEl(c));

    // The footnote block sits below every row, so the room a page has for
    // content is its own height less whatever that block takes.  Measuring the
    // rows against that reduced bottom is what makes a page carrying footnotes
    // split early enough to hold them.
    //
    // This is the only thing reserving that room on an authored-page printout:
    // those pages are the author's, so they never go through findPageBreaks(),
    // where the same budget is applied when pages are planned from scratch.
    // Without it the block simply rendered past the foot of the sheet -- and
    // since a page box only clips when actually printing, on screen it spilled
    // into the gap below and read as the top of the next page.
    //
    // Reserving the block's *current* height is always enough, and never traps
    // the layout in a cycle: rows only ever move off this page, and every
    // footnote leaving with one makes the block smaller, never bigger.
    const footnotes = [...page.children].find(c => c.classList.contains('footnotes'));
    const contentBottom = getPageContentBottom(page) - (footnotes ? getElementTotalHeight(footnotes) : 0);

    let overflowStartIndex = -1;
    for (let j = 0; j < contentChildren.length; j++) {
      const r = contentChildren[j].getBoundingClientRect();
      if (r.bottom > contentBottom + 1) {
        overflowStartIndex = j;
        break;
      }
    }
    if (overflowStartIndex === -1) continue; // this page fits fine, leave it completely alone
    if (overflowStartIndex === 0) {
      // The very first row alone is already too tall to fit on any page —
      // nothing we can do about that specific row. But if there are other
      // rows after it, they shouldn't be trapped here too: move everything
      // after the oversized first row onto a fresh page.
      if (contentChildren.length <= 1) continue; // truly nothing else to move
      overflowStartIndex = 1;
    }
    // This is the runtime counterpart of the rules findPageBreaks() applies
    // when it plans pages from scratch, and it has to enforce them too: a
    // reveal goes through here (applySolutionVisibility() repaginates with
    // fullRecompute false), so without this a revealed solution can push its
    // own workspace onto the next page and open that page with a slab of
    // blank writing space, or tear a question away from its solutions.
    // Both are fixed the same way -- retreat to an earlier, legal split.
    while (overflowStartIndex > 1) {
      const row = contentChildren[overflowStartIndex];
      const prev = contentChildren[overflowStartIndex - 1];
      const opensWithWorkspace = isVisibleWorkspaceRow(row);
      const splitsGroup = !!(row.dataset.blockGroup &&
                             row.dataset.blockGroup === prev.dataset.blockGroup);
      if (!opensWithWorkspace && !splitsGroup) break;
      overflowStartIndex--;
    }

    const overflowElems = contentChildren.slice(overflowStartIndex);
    const newPage = document.createElement('section');
    newPage.classList.add('onepage', 'spillover');
    if (page.classList.contains('lastpage')) {
      page.classList.remove('lastpage');
      newPage.classList.add('lastpage');
    }
    overflowElems.forEach(el => newPage.appendChild(el));
    page.parentNode.insertBefore(newPage, page.nextSibling);

    [...page.children].filter(isPageFurnitureEl).forEach(hf => hf.remove());

    pages.splice(i + 1, 0, newPage); // let the loop also check the new page for cascading overflow
  }

  printout.querySelectorAll(':scope > .onepage').forEach(p => {
    [...p.children].filter(isPageFurnitureEl).forEach(hf => hf.remove());
  });
  addHeadersAndFootersToPrintout();
}

// Append `children` onto the end of a page's *content*, i.e. ahead of whatever
// tail furniture is already attached. Pages being merged in
// collapseSpilloverPages() still have their old footnote block and footer in
// place (furniture isn't stripped until after the whole merge pass finishes),
// so a plain appendChild would land new content after them -- corrupting both
// the reading order and the overflow measurement used to judge the merge.
function appendPageContent(page, children) {
    const tail = [...page.children].find(isPageTailEl);
    children.forEach(c => page.insertBefore(c, tail || null));
}

// Eagerly fold every spillover page's content back into the page before it,
// unconditionally -- i.e. without checking whether the merged page fits yet.
// That check is intentionally left to the caller (via adjustWorkspaceOrRepaginate,
// which shrinks workspace boxes to fit before measuring overflow, then
// re-splits with addSpilloverPages() if something still doesn't fit).
// Deciding here, before workspace has a chance to shrink back down from
// whatever size it was left at by the previous, more spread-out layout,
// is unreliable: a page can measure as overflowing purely because its
// workspace boxes are still sized for the old layout, when shrinking them
// would actually make room.
//
// Processing pages highest-index-first guarantees that a spillover page's
// merge target (the page right before it) hasn't itself already been
// removed by an earlier step in this same pass, so chains of cascaded
// spillover pages collapse correctly in a single pass.
function collapseSpilloverPages(margins) {
  const printout = getPrintout();
  if (!printout) return;
  const pages = [...printout.querySelectorAll(':scope > .onepage')];

  for (let i = pages.length - 1; i >= 1; i--) {
    const page = pages[i];
    if (!page.classList.contains('spillover')) continue;
    const prevPage = pages[i - 1];

    const contentChildren = [...page.children].filter(c => !isPageFurnitureEl(c));
    appendPageContent(prevPage, contentChildren);
    if (page.classList.contains('lastpage')) {
      prevPage.classList.add('lastpage');
    }
    page.remove();
  }

  printout.querySelectorAll(':scope > .onepage').forEach(p => {
    [...p.children].filter(isPageFurnitureEl).forEach(hf => hf.remove());
  });
  addHeadersAndFootersToPrintout();
}

// Lists //

// Pagination places whole rows, so a list can only break across a page
// boundary if it is several rows.  Splitting one is destructive in ways that
// matter -- the pieces leave the block that held them, so a list inside a
// decorated block (an "objectives" panel, say) loses that decoration, and a
// list the reader sees as one thing becomes several -- so it is done only for
// a list that cannot fit on a page whole, where the alternative is not an
// intact list but a clipped one.  Everything below is reached only from
// flattenOversizedListsIn(), which applies that test.

// The element that starts each piece a list is cut into: every item of an
// ol/ul, and every term of a dl (whose items the XSL renders as a <dt>/<dd>
// pair, which has to stay together).
function isListChunkStart(elem, list) {
    return list.tagName === 'DL' ? elem.tagName === 'DT' : elem.tagName === 'LI';
}

// Whether `elem` is a list element at all.
function isListEl(elem) {
    return elem.tagName === 'OL' || elem.tagName === 'UL' || elem.tagName === 'DL';
}

// The lists in `row` that may be cut up.  Nested lists are left to their
// outermost ancestor, which takes them along inside whichever item holds them;
// a list laid out in columns is left alone entirely, since cutting it into
// single-item lists would throw the columns away.
//
// The row may *be* a list rather than contain one -- flattenIntroductionsIn()
// hoists an introduction's children up to be rows in their own right, and a
// list among them arrives here as a top-level row -- and querySelectorAll, which
// looks only at descendants, does not see that case at all.
function splittableListsIn(row) {
    const candidates = isListEl(row) ? [row] : [...row.querySelectorAll('ol, ul, dl')];
    return candidates.filter(list =>
        !list.closest('.sidebyside') &&
        !(list !== row && list.parentElement.closest('ol, ul, dl')) &&
        ![...list.classList].some(cls => /^cols\d+$/.test(cls))
    );
}

// Cut `list` into one list per item and hoist the pieces out to be top-level
// rows of `container`, immediately after the row `child` that held it, so that
// pagination can weigh -- and break between -- each item on its own.
//
// Each piece is a list element of its own, cloned from the original's tag and
// classes rather than an <li> hoisted bare, so an item keeps its marker and its
// indentation; an ordered list's pieces carry `start`, so the numbering runs on
// through the break instead of restarting at 1 on every page.
//
// Whatever followed the list inside `child` has to come out too, at every level
// between the two.  Otherwise it stays behind inside `child` -- which is still
// a row *above* the pieces just hoisted -- and a closing sentence after a list
// would be rendered before the list it closes.  Only elements are taken: in
// this HTML every run of text is inside a .para of its own, and a bare text
// node hoisted to be a row would be stray inline content in a page box.
function hoistListOut(container, child, list) {
    // When the row *is* the list there is no block around it to come out of,
    // so the pieces stand exactly where it stood and inherit its classes --
    // including whatever indent it was carrying -- by the clone below.
    const isRowItself = list === child;
    // Read before anything moves; see depthClassForRowOut().
    const depthClass = isRowItself ? null : depthClassForRowOut(child);
    // Collected bottom-up, which is reading order: everything after the list
    // itself, then everything after the wrapper that held the list, and so on
    // out to `child`.
    const tail = [];
    for (let node = list; node !== child; node = node.parentElement) {
        for (let sib = node.nextElementSibling; sib; sib = sib.nextElementSibling) {
            tail.push(sib);
        }
    }
    const pieces = [];
    let piece = null;
    // `start` counts items, not children, so a dl's <dd> must not advance it.
    let itemNumber = parseInt(list.getAttribute('start'), 10) || 1;
    for (const item of [...list.children]) {
        if (isListChunkStart(item, list) || piece === null) {
            piece = document.createElement(list.tagName);
            piece.className = list.className;
            piece.classList.add('split-list');
            if (list.tagName === 'OL') {
                piece.setAttribute('start', String(itemNumber));
            }
            itemNumber++;
            pieces.push(piece);
        }
        piece.appendChild(item);
    }
    if (pieces.length === 0) return;
    // The first piece stays where the list was, rather than being hoisted with
    // the rest.  It keeps the block it came from non-empty, so a heading that
    // introduces the list -- an exercise number, typically -- cannot be left
    // stranded at the foot of a page with the list it belongs to starting on
    // the next one.  When the row is the list itself this simply puts the first
    // piece in the row's own place.
    list.parentNode.insertBefore(pieces[0], list);
    list.remove();
    if (!isRowItself) {
        // The block now holds one item of a list that runs on outside it, so
        // its own decoration -- a panel border, a tinted background -- would be
        // drawn around that single item and read as though the list ended
        // there.  The print stylesheet drops it; see `.split-block`.
        child.classList.add('split-block');
    }
    let anchor = isRowItself ? pieces[0] : child;
    for (const row of [...pieces.slice(1), ...tail]) {
        container.insertBefore(row, anchor.nextSibling);
        if (depthClass) {
            row.classList.add(depthClass);
        }
        anchor = row;
    }
}

// Split up the lists inside any row of `container` that is taller than a page.
//
// Such a row cannot be placed whole however the breaks fall: findPageBreaks()
// hands it a page of its own and addSpilloverPages() declines to touch it, and
// then `overflow: hidden` on the page box silently cuts off everything past the
// bottom of the sheet.  A list is the one part of such a row that can be broken
// up without loss, so it is, and only then.
//
// Returns whether anything moved, since the caller has to re-read its rows and
// measure again if so.
function flattenOversizedListsIn(container, pageHeight) {
    let split = false;
    for (const child of [...container.children]) {
        if (getElementTotalHeight(child) <= pageHeight) continue;
        const lists = splittableListsIn(child);
        if (lists.length === 0) continue;
        // Innermost-last, so hoisting one cannot invalidate the position of
        // another still to be done: each hoist only moves nodes at or after
        // `list`, and taking the last one first leaves the earlier ones, and
        // the ancestors they hang off, exactly where they were.
        for (let i = lists.length - 1; i >= 0; i--) {
            hoistListOut(container, child, lists[i]);
        }
        split = true;
    }
    return split;
}

// Footnotes //

// A printout sets footnotes the way a book does: the marker stays inline where
// the reference is, and the text is collected into a block at the foot of
// whichever page that reference lands on.  Everything below is built on
// *cloning* the text into that block rather than moving it there, which is what
// keeps the whole scheme compatible with a paginator that moves rows around
// freely: the authored DOM is never touched, so a row can be pushed onto a
// spillover page, merged back, or re-measured without anything needing to be
// restored, and the block is simply thrown away and rebuilt from scratch on the
// far side (see rebuildFootnotes(), called from addHeadersAndFootersToPrintout()
// alongside the header and footer bands, which are handled exactly this way).
//
// The original footnote stays inline as a closed <details>, showing its marker
// and nothing else; the print stylesheet keeps its contents out of sight even
// if the <details> is somehow opened.

// The footnotes referenced somewhere inside `root`, in document order.
//
// A footnote inside a hidden hint/answer/solution is not on the page, so it
// gets no entry at the foot of it -- and picks one up, through the ordinary
// repagination that a reveal already triggers, as soon as it is shown.
function footnoteDetailsIn(root) {
    return [...root.querySelectorAll('details.ptx-footnote')].filter(fn => !fn.closest('.hidden'));
}

// The number a footnote is marked with inline, which is also what its entry at
// the foot of the page is labelled with.  Read off the marker the XSL emitted
// rather than counted here, so the numbering in a printout is the same
// numbering the same footnote carries everywhere else in the book.
function footnoteMark(details) {
    const sup = details.querySelector('.ptx-footnote__number sup');
    return sup ? sup.textContent.trim() : '';
}

// One entry -- number plus text -- for the block at the foot of the page.
function buildFootnoteItem(details) {
    const item = document.createElement('div');
    item.classList.add('footnote-item');
    const number = document.createElement('sup');
    number.classList.add('footnote-item__number');
    number.textContent = footnoteMark(details);
    item.appendChild(number);
    const contents = details.querySelector('.ptx-footnote__contents');
    if (contents) {
        const clone = contents.cloneNode(true);
        // The original stays in the document, so every id in the copy would be
        // a duplicate of one still live elsewhere on the page -- including the
        // footnote's own, which the XSL already puts on both the <details> and
        // the contents div.  Nothing needs to address the copy, and
        // getElementById() picking it over the real element (loadPrintout()
        // resolves ?printpreview= that way) is a real hazard, so drop them all.
        clone.removeAttribute('id');
        clone.querySelectorAll('[id]').forEach(el => el.removeAttribute('id'));
        // Down here it is a run of text after a number, not the bordered knowl
        // box the class styles it as in the body of the page.
        clone.classList.remove('ptx-footnote__contents');
        clone.classList.add('footnote-item__contents');
        item.appendChild(clone);
    }
    return item;
}

function buildFootnotesBlock(detailsList) {
    const block = document.createElement('div');
    block.classList.add('footnotes');
    detailsList.forEach(details => block.appendChild(buildFootnoteItem(details)));
    return block;
}

// Give every page the footnote text its own content references, replacing
// whatever it was given last time.  Idempotent by construction -- it clears
// before it builds -- so it is safe to call after any repagination, however
// much or little actually moved.
function rebuildFootnotes() {
    const printout = getPrintout();
    if (!printout) return;
    printout.querySelectorAll(':scope > .onepage > .footnotes').forEach(block => block.remove());
    printout.querySelectorAll(':scope > .onepage').forEach(page => {
        const notes = footnoteDetailsIn(page);
        if (notes.length === 0) return;
        appendPageContent(page, [buildFootnotesBlock(notes)]);
    });
}

// What the footnote block will cost a page, measured in the same throwaway
// .onepage the rows themselves are being measured in (see createPrintoutPages())
// so that it wraps at the real page width and under the real print stylesheet.
//
// Footnote text does not sit where its reference does, so it is not part of any
// row's own height, and a page planned without it overflows by exactly the
// amount it takes.  Returns the height each row's own footnotes contribute,
// which findPageBreaks() charges to that row, and separately the block's fixed
// overhead -- its rule, padding and margins -- which a page pays once if it
// carries any footnote at all.
function measureFootnotes(rows, measuringPage) {
    const heights = new Map();
    const owners = [];
    for (const row of rows) {
        for (const details of footnoteDetailsIn(row)) {
            owners.push({details, row});
        }
    }
    if (owners.length === 0) return {heights, chrome: 0};
    const probe = buildFootnotesBlock(owners.map(o => o.details));
    measuringPage.appendChild(probe);
    let itemTotal = 0;
    [...probe.children].forEach((item, i) => {
        const height = getElementTotalHeight(item);
        itemTotal += height;
        const row = owners[i].row;
        heights.set(row, (heights.get(row) || 0) + height);
    });
    // Whatever the block costs beyond its entries.  Derived by subtraction
    // rather than read off the stylesheet so that restyling the block cannot
    // quietly desynchronise the budget from what actually gets rendered.
    const chrome = Math.max(0, getElementTotalHeight(probe) - itemTotal);
    probe.remove();
    return {heights, chrome};
}

// Add headers and footers to all pages in a printout.  Start with this set to be hidden by default; a toggle later will show/hide them.
function addHeadersAndFootersToPrintout() {
    const printout = getPrintout();
    if (!printout) {
        console.warn("No printout found, exiting addHeadersAndFootersToPrintout.");
        return;
    }
    // The footnote block is page furniture on the same terms as the bands
    // below -- derived from whatever content the page ended up with, and so
    // rebuilt whenever that changes -- and it goes on first, since it belongs
    // between the content and the footer.
    rebuildFootnotes();
    const pages = printout.querySelectorAll('.onepage');
    // Loop through pages and add header and footer divs. This function gets
    // called every time pagination is rebuilt (resetPrintoutPagination(),
    // addSpilloverPages(), collapseSpilloverPages(), ...), not just once at
    // initial load, so the hidden/visible state has to be decided here from
    // localStorage directly -- not left hidden for some later one-time setup
    // step to correct, which would only ever apply to the *first* build and
    // leave every rebuild after it hidden regardless of the checkbox state.
    pages.forEach((page, index) => {
        const isFirstPage = index === 0;
        const headerClass = isFirstPage ? 'first-page-header' : 'running-header';
        const footerClass = isFirstPage ? 'first-page-footer' : 'running-footer';
        // Add header
        const headerDiv = document.createElement('div');
        headerDiv.classList.add(headerClass);
        if (localStorage.getItem(`print-${headerClass}`) !== "true") {
            headerDiv.classList.add('hidden');
        }
        headerDiv.innerHTML = `<div class="header-left" contenteditable="true"></div><div class="header-center" contenteditable="true"></div><div class="header-right" contenteditable="true"></div>`;
        page.insertBefore(headerDiv, page.firstChild);
        // Add footer
        const footerDiv = document.createElement('div');
        footerDiv.classList.add(footerClass);
        if (localStorage.getItem(`print-${footerClass}`) !== "true") {
            footerDiv.classList.add('hidden');
        }
        footerDiv.innerHTML = `<div class="footer-left" contenteditable="true"></div><div class="footer-center" contenteditable="true"></div><div class="footer-right" contenteditable="true"></div>`;
        page.appendChild(footerDiv);
    });
    // Add content based on local storage if available, otherwise from data-attributes on the printout
    const headerFooterKeys = ['header-first-left', 'header-first-center', 'header-first-right', 'footer-first-left', 'footer-first-center', 'footer-first-right', 'header-running-left', 'header-running-center', 'header-running-right', 'footer-running-left', 'footer-running-center', 'footer-running-right'];
    const headerFooterContent = {};
    headerFooterKeys.forEach(key => {
        headerFooterContent[key] = localStorage.getItem(key) || printout.getAttribute(`data-${key}`) || '';
    });
    // First page header and footer
    document.querySelector('.first-page-header').querySelector('.header-left').innerHTML = headerFooterContent['header-first-left'];
    document.querySelector('.first-page-header').querySelector('.header-center').innerHTML = headerFooterContent['header-first-center'];
    document.querySelector('.first-page-header').querySelector('.header-right').innerHTML = headerFooterContent['header-first-right'];
    document.querySelector('.first-page-footer').querySelector('.footer-left').innerHTML = headerFooterContent['footer-first-left'];
    document.querySelector('.first-page-footer').querySelector('.footer-center').innerHTML = headerFooterContent['footer-first-center'];
    document.querySelector('.first-page-footer').querySelector('.footer-right').innerHTML = headerFooterContent['footer-first-right'];
    // Running headers and footers
    document.querySelectorAll('.running-header').forEach(headerDiv => {
        headerDiv.querySelector('.header-left').innerHTML = headerFooterContent['header-running-left'];
        headerDiv.querySelector('.header-center').innerHTML = headerFooterContent['header-running-center'];
        headerDiv.querySelector('.header-right').innerHTML = headerFooterContent['header-running-right'];
    });
    document.querySelectorAll('.running-footer').forEach(footerDiv => {
        footerDiv.querySelector('.footer-left').innerHTML = headerFooterContent['footer-running-left'];
        footerDiv.querySelector('.footer-center').innerHTML = headerFooterContent['footer-running-center'];
        footerDiv.querySelector('.footer-right').innerHTML = headerFooterContent['footer-running-right'];
    });
    // Add event listeners to update local storage when content is edited
    headerFooterKeys.forEach(key => {
        const selectorMap = {
            'header-first-left': '.first-page-header .header-left',
            'header-first-center': '.first-page-header .header-center',
            'header-first-right': '.first-page-header .header-right',
            'footer-first-left': '.first-page-footer .footer-left',
            'footer-first-center': '.first-page-footer .footer-center',
            'footer-first-right': '.first-page-footer .footer-right',
            'header-running-left': '.running-header .header-left',
            'header-running-center': '.running-header .header-center',
            'header-running-right': '.running-header .header-right',
            'footer-running-left': '.running-footer .footer-left',
            'footer-running-center': '.running-footer .footer-center',
            'footer-running-right': '.running-footer .footer-right'
        };
        const elements = document.querySelectorAll(selectorMap[key]);
        elements.forEach(elem => {
            elem.addEventListener('input', () => {
                localStorage.setItem(key, elem.innerHTML);
            });
        });
    });
}


// We look at each page and adjust the heights of the workspaces to fit it nicely into the page.
// The width and height of the page will now depend on the letter or a4 setting.
function adjustWorkspaceToFitPage({paperSize, margins}) {
    console.log("*** Adjusting workspace to fit page size:", paperSize, "with margins:", margins);

    // Toggle off workspace highlight if it is on, so it doesn't interfere with resizing
    const highlightWorkspaceCheckbox = document.getElementById("highlight-workspace-checkbox");
    const wasHighlighted = highlightWorkspaceCheckbox && highlightWorkspaceCheckbox.checked;
    if (wasHighlighted) {
        toggleWorkspaceHighlight(false);
    }

    let paperWidth, paperHeight;
    if (paperSize === 'a4' || document.body.classList.contains('a4')) {
        console.log("Setting page size to A4");
        paperWidth = 794; // 210mm in px
        paperHeight = 1122.5; // 297mm in px 794px x 1122.5px
    } else {
        console.log("Setting page size to Letter");
        paperWidth = 816; // 8.5in in px
        paperHeight = 1056; // 11in in px
    }
    const paperContentHeight = paperHeight - (margins.top + margins.bottom);

    // Reset the heights of workspace divs to their author-provided heights
    setInitialWorkspaceHeights();
    // Bottom-anchoring a footnote block (below) is done by growing its top
    // margin, so clear that first: left in place it measures as content, and
    // each pass would push the block down by the slack the previous pass had
    // already taken up.
    document.querySelectorAll('.onepage > .footnotes').forEach(block => {
        block.style.marginTop = "";
    });

    const pages = document.querySelectorAll('.onepage');
    pages.forEach(page => {
        console.log("Adjusting workspace height for page:", page);
        // Set width to get accurate calculations
        page.style.width = paperWidth + 'px';
        const rows = page.children;
        let totalContentHeight = 0;
        let totalWorkspaceHeight = 0;
        for (const row of rows) {
            totalContentHeight += getElementTotalHeight(row);
            totalWorkspaceHeight += getElemWorkspaceHeight(row);
        }
        if (totalWorkspaceHeight === 0) {
            // With no writing space to stretch, nothing else on this page will
            // grow to fill it, so a footnote block would sit directly beneath
            // the last line of content, stranded mid-page.  A book sets its
            // footnotes at the foot of the page, so push the block down into
            // whatever room is left over.  Only ever into slack that already
            // exists -- and a pixel short of it -- so this can never be what
            // makes a page overflow.
            const footnotes = [...page.children].find(c => c.classList.contains('footnotes'));
            if (footnotes) {
                // Measured from where the block has actually been laid out,
                // rather than from the summed row heights: read off the page
                // itself, the push can only ever close a gap that is really
                // there, so no error in that accounting can drive the block
                // off the foot of the sheet.
                const gap = getPageContentBottom(page) - footnotes.getBoundingClientRect().bottom - 1;
                if (gap > 0) {
                    const baseMargin = parseFloat(getComputedStyle(footnotes).marginTop) || 0;
                    footnotes.style.marginTop = (baseMargin + gap) + "px";
                }
            }
            console.log("No workspaces on this page, skipping workspace adjustment.");
            // Reset the style for the page
            page.style.width = "";
            return;
        }
        const extraHeight = paperContentHeight - totalContentHeight;
        console.log("Extra height to distribute across workspaces:", extraHeight, "px.");
        // Determine the factor by which to multiply each workspace to make the total height fit the paperContentHeight
        const workspaceAdjustmentFactor = (totalWorkspaceHeight + extraHeight) / totalWorkspaceHeight;
        console.log("Workspace adjustment factor for page:", workspaceAdjustmentFactor);
        // Now adjust each workspace in the page by this factor
        const pageWorkspaces = page.querySelectorAll('.workspace');
        pageWorkspaces.forEach(ws => {
            const originalHeight = ws.offsetHeight;
            const newHeight = originalHeight * workspaceAdjustmentFactor;
            ws.style.height = newHeight + "px";
        });
        // Reset the style for the page
        page.style.width = "";
    });
    console.log("Set page sizes to content area of paper size.");

    // Reset the highlight workspace checkbox state
    if (wasHighlighted) {
        toggleWorkspaceHighlight(true);
    }
}

// Helper functions for calculating heights and workspace sizes
function getElementTotalHeight(elem) {
    // Calculate the total height of the element, including padding, border, and top margin.
    const style = getComputedStyle(elem);
    const marginTop = parseFloat(style.marginTop);
    const marginBottom = parseFloat(style.marginBottom);
    const height = elem.offsetHeight;
    return height + marginTop + marginBottom;
}

function getElemWorkspaceHeight(elem) {
    // Calculate the total height of all workspaces in the element.
    // This is easy for elements stacked vertically, but we must be careful for side-by-side workspaces.  Since we will multiply each workspace by a factor to fit the page, taking the largest workspace height should give us an upper bound for the amount of vertical space that is workspace.
    // Note that this won't work well if we need to reduce the workspace, since there we would want to take the minimum heights.
    if (elem.classList.contains('sidebyside')) {
        const sbspanels = elem.querySelectorAll('.sbspanel');
        let max = 0;
        sbspanels.forEach(panel => {
            const workspaces = panel.querySelectorAll('.workspace');
            let totalHeight = 0;
            workspaces.forEach(workspace => {
                const workspaceHeight = workspace.offsetHeight;
                if (workspaceHeight) {
                    totalHeight += workspaceHeight;
                }
            });
            if (totalHeight > max) {
                max = totalHeight; // Take the maximum height of workspaces in sidebyside
            }
        });
        return max; // Return the maximum height of workspaces in sidebyside
    }
    // We can take care of exercisegroups and single colomn regular layout together.
    let columns = 1;
    if (elem.classList.contains('exercisegroup')) {
        // Check for column classes and set columns accordingly
        for (let i = 2; i <= 6; i++) {
            if (elem.querySelector(`.cols${i}`)) {
            columns = i;
            console.log("Found exercisegroup with columns:", columns);
            break;
            }
        }
    }
    const workspaces = workspaceDivsIn(elem);
    let totalHeight = 0;
    workspaces.forEach(ws => {
        const workspaceHeight = ws.offsetHeight;
        if (workspaceHeight) {
            totalHeight += workspaceHeight;
        }
    });
    return totalHeight / columns; // Divide by columns if sidebyside to get average height per column
}

// Cost of one candidate page holding rows [i..j], in the same units as the
// original objective: (px of wasted space)^2, so that the penalties below
// trade off directly against blank space -- a penalty of P is "worth" about
// sqrt(P) px of waste at the foot of a page.
//
//   naturalHeight   total height with every workspace at its authored size
//   workspaceHeight how much of that is blank writing space, i.e. how much
//                   can be given back by squeezing (adjustWorkspaceToFitPage()
//                   scales workspaces by a factor below 1 when a page is over
//                   budget, so a page may legitimately be planned as "fits
//                   only once squeezed") -- and, on a page that fits, how much
//                   of the leftover room will be soaked up rather than left
//                   blank, since the same function stretches the workspaces on
//                   an under-full page to fill it
//   splitsGroup     true when the break after row j separates a question from
//                   its own solutions or workspace
//   isLastPage      true when this page ends the printout, so the room left at
//                   its foot is where the remainder is *meant* to collect
//
// Returns Infinity for a page that cannot be made to fit at all.
//
// NB the two constants are the tuning knobs for "keep an exercise with its
// solutions and workspace together, and only spill over if absolutely
// necessary": raising GROUP_BREAK_PENALTY_PAGES buys cohesion at the price of
// more blank space, and lowering SQUEEZE_COST_SCALE makes the layout more
// willing to eat into writing space before it gives up and splits.
//
// The group penalty is expressed in whole wasted pages rather than as a raw
// number so that it scales with paper size instead of being tuned for one:
// at 1, separating a question from its own solutions or workspace is judged
// exactly as costly as leaving a whole page blank, which is what makes the
// optimiser exhaust every other option -- including squeezing away all the
// writing space, and pushing the whole group to the next page -- first.
const GROUP_BREAK_PENALTY_PAGES = 1;
const SQUEEZE_COST_SCALE = 0.25;        // squeezing s px of workspace costs 0.25*s^2

// How leftover room at the foot of a page is charged when nothing on that page
// will grow into it -- see deadSpaceCost().  Below 1 the cost is concave, which
// is what makes the optimiser pack the early pages full and let the remainder
// gather at the end: of two layouts that waste the same total, the one that
// wastes it all in a single gap is cheaper than the one that spreads it evenly.
// (The squared cost used for room a workspace will soak up does the opposite,
// deliberately -- see pageCost().)
const DEAD_SPACE_EXPONENT = 0.75;

// Whether any hint/answer/solution is currently revealed in the printout.
// Checks effective visibility -- the element and every ancestor free of
// "hidden" -- because rewriteSolutions() puts the "hidden" class on the
// wrapper it builds, while the original `.knowl__content` div inside it never
// carries the class itself.
function anySolutionShown() {
    const printout = getPrintout();
    if (!printout) return false;
    return [...printout.querySelectorAll('.hint, .answer, .solution')].some(el => !el.closest('.hidden'));
}

// What `slack` px of unused room at the foot of a page costs when no workspace
// on the page will grow into it -- blank paper the reader gets nothing for.
//
// Free on the final page: a printout almost never ends exactly at a page
// boundary, so *some* page has to carry the remainder, and the last one is
// where a reader expects it.  Charging for it is what used to make a long list
// come out halved, with a matching gap at the foot of both pages: with the cost
// squared, two gaps of h/2 beat one gap of h, so the optimiser preferred to
// split the difference rather than fill the first page.
//
// Everywhere else the cost is concave (DEAD_SPACE_EXPONENT below 1), so that
// preference is reversed at every page count, not just the last: leaving a
// little room on each of several pages costs more than leaving all of it on
// one, so each page is filled as far as the rows allow and what is left over
// is pushed towards the end.
//
// Scaled so that a wholly blank page still costs pageHeight^2 -- exactly one
// wasted page, the same as before -- which keeps GROUP_BREAK_PENALTY_PAGES
// calibrated: no single page's blank space can outweigh keeping a question
// with its own solutions and workspace, whatever the paper size.
function deadSpaceCost(slack, pageHeight, isLastPage) {
    if (isLastPage) return 0;
    return pageHeight ** 2 * (slack / pageHeight) ** DEAD_SPACE_EXPONENT;
}

function pageCost({ pageHeight, naturalHeight, workspaceHeight, splitsGroup, allowSqueeze, squeezeIsForced, isLastPage }) {
    const groupPenalty = splitsGroup ? GROUP_BREAK_PENALTY_PAGES * pageHeight ** 2 : 0;
    if (naturalHeight <= pageHeight) {
        // Fits as authored.  What the room left over is worth depends on what
        // becomes of it once the page is built.
        const slack = pageHeight - naturalHeight;
        if (workspaceHeight > 0) {
            // adjustWorkspaceToFitPage() will hand every px of it to the
            // writing space on this page, so none of it is actually wasted --
            // it turns into room the author asked for.  Squared, as it always
            // has been, precisely because that spreads the extra evenly over a
            // run of such pages: every workspace grows a little, rather than
            // one page's workspace growing enormously so that another's can
            // stay at its authored size.
            return slack ** 2 + groupPenalty;
        }
        // Nothing here grows, so the room is simply blank paper.
        return deadSpaceCost(slack, pageHeight, isLastPage) + groupPenalty;
    }
    // Over budget at the authored workspace sizes.  Blank writing space is
    // compressible, but eating into it to merely pack pages tighter is only
    // acceptable once a hint/answer/solution is on the page taking up the
    // room -- with nothing revealed, the author asked for that much space to
    // write in and must get at least that much, even at the cost of extra
    // pages.
    //
    // The exception is a page holding a row that is taller than the page all
    // by itself.  There, squeezing is not an optimisation, it is the only way
    // that row is ever going to fit, and refusing it does not preserve any
    // writing space -- it just strands the row on a page of its own and, worse,
    // leaves whatever small thing preceded it (a worksheet title, typically)
    // alone on the page before.  So allow it whenever it is forced.
    if (!allowSqueeze && !squeezeIsForced) {
        return Infinity;
    }
    const squeeze = naturalHeight - pageHeight;
    if (squeeze > workspaceHeight) {
        return Infinity; // no amount of squeezing saves this page
    }
    // Nothing is wasted (the page is exactly full), but squeezing writing
    // space has its own cost, so a merely-tight page still loses to a roomy one.
    return SQUEEZE_COST_SCALE * squeeze ** 2 + groupPenalty;
}

// Functions for finding the optimal page breaks.
//
// `allowSqueeze` permits planning a page that only fits once its blank
// writing space is compressed.  It is off unless a hint/answer/solution is
// actually being shown: a worksheet with nothing revealed must honour the
// authored workspace heights in full.
//
// `footnoteChrome` is the fixed overhead of the footnote block (see
// measureFootnotes()), charged once to any page that carries a footnote.
function findPageBreaks(rows, pageHeight, { allowSqueeze = false, footnoteChrome = 0 } = {}) {
    console.log("*** Finding page breaks for", rows.length, "rows with page height:", pageHeight);
    // An array for the page breaks.  The nth element will be the index of the first row on page n+1.
    let pageBreaks = [];
    // An array for the minimum cost possible for rows i to the end.
    let minCost = Array(rows.length + 1).fill(Infinity);
    minCost[rows.length] = 0; // No cost for no rows
    // An array to keep track of the next row to start a new page after i in minCost.
    let nextPageBreak = Array(rows.length).fill(-1);

    // Now loop through the rows in reverse order to find the optimal page breaks.
    for (let i = rows.length - 1; i >= 0; i--) {
        let cumulativeHeight = 0;
        let cumulativeWorkspaceHeight = 0;
        let cumulativeFootnoteHeight = 0;
        let tallestRow = 0;
        // Loop through the rows starting from i to find the best page break
        for (let j = i; j < rows.length; j++) {
            cumulativeHeight += rows[j].height;
            cumulativeWorkspaceHeight += rows[j].workspaceHeight;
            cumulativeFootnoteHeight += rows[j].footnoteHeight || 0;
            // The footnote block is only on the page if something on the page
            // referenced a footnote, and then it costs its own rule and padding
            // once, however many entries it ends up holding.
            const footnotesHeight = cumulativeFootnoteHeight > 0
                ? cumulativeFootnoteHeight + footnoteChrome
                : 0;
            // A row taller than a whole page cannot be placed at its authored
            // size no matter how the breaks fall, so squeezing is forced for
            // any page that has to hold it -- see pageCost().  A row drags its
            // own footnotes onto the page with it, so it is the pair that has
            // to fit, not the row alone.
            const rowWithNotes = rows[j].footnoteHeight
                ? rows[j].height + rows[j].footnoteHeight + footnoteChrome
                : rows[j].height;
            tallestRow = Math.max(tallestRow, rowWithNotes);
            const next = rows[j + 1];

            const thisPage = pageCost({
                pageHeight,
                naturalHeight: cumulativeHeight + footnotesHeight,
                workspaceHeight: cumulativeWorkspaceHeight,
                splitsGroup: !!(next && rows[j].group && rows[j].group === next.group),
                allowSqueeze,
                squeezeIsForced: tallestRow > pageHeight,
                isLastPage: j === rows.length - 1,
            });
            if (thisPage === Infinity) {
                // This page overflows even with all its writing space squeezed
                // away, and every longer page would too, so stop extending it.
                if (j === i) {
                    // The page height is too big for a single row.  We make this row its own page and move on.
                    console.log("Row", i, "exceeds page height by itself, setting as its own page.");
                    minCost[i] = 0; // No cost for a single row
                    nextPageBreak[i] = i + 1; // The next page break is after this row
                }
                break;
            }
            // A page must never open with blank writing space: a workspace
            // row belongs under the question it was authored for, so breaking
            // right before one is simply not a legal break.  (When the group
            // genuinely cannot be held together, the workspace is suppressed
            // later instead -- see hideWidowedWorkspaces().)
            if (next && next.isWorkspace) continue;

            const cost = thisPage + minCost[j + 1]; // plus the cost of the following pages
            if (cost < minCost[i]) {
                minCost[i] = cost;
                nextPageBreak[i] = j + 1; // Set the next page break to be after row j
            }
        }
        // Every candidate break was illegal (e.g. the only places to break
        // were immediately before a workspace row).  Fall back to giving row i
        // a page of its own so backtracking below always makes progress
        // rather than looping on nextPageBreak === -1.
        if (nextPageBreak[i] === -1) {
            nextPageBreak[i] = i + 1;
            minCost[i] = minCost[i + 1];
        }
    }
    // Backtrack to find the actual page breaks based on nextPageBreak
    // Note: nextPage used to be set to 1.
    // This meant the very first page's title height was never counted against that page's budget during optimization, even though it still occupied real space once pages were built.
    // This caused the first page to sometimes exceed capacity, and the resulting correction to cascade into large wasted-space gaps on later pages.
    let nextPage = 0;
    while (nextPage < rows.length) {
        pageBreaks.push(nextPageBreak[nextPage]);
        nextPage = nextPageBreak[nextPage];
    }
    return pageBreaks;
}

// Function to set CSS variables and @page rules for page geometry.  This will be called whenever the paper size or margins change (in practice, only when page size changes, since margins are fixed for now).
function setPageGeometryCSS({paperSize, margins}) {
    console.log("*** Setting page geometry CSS for paper size:", paperSize, "with margins:", margins);
    // Remove any existing geometry CSS to avoid duplicates
    const existingStyle = document.getElementById("page-geometry-css");
    if (existingStyle) {
        existingStyle.remove();
    }
    let wsWidth = paperSize === "letter" ? "816px" : "794px"; // 8.5in for Letter, 210mm for A4
    let wsHeight = paperSize === "letter" ? "1056px" : "1123px"; // 11in for Letter, 297mm for A4
    // Create a new style element for geometry CSS
    const style = document.createElement("style");
    // Add an identifier to the style element to avoid conflicts
    style.id = "page-geometry-css";
    // NB we need to add the fallback values for the margins in @page because some browsers do not support CSS variables in @page rules.
    style.textContent = `
        :root {
            --ws-width: ${wsWidth};
            --ws-height: ${wsHeight};
            --ws-top-margin: ${margins.top}px;
            --ws-right-margin: ${margins.right}px;
            --ws-bottom-margin: ${margins.bottom}px;
            --ws-left-margin: ${margins.left}px;
        }
        @page {
            margin: var(--ws-top-margin, ${margins.top}px) var(--ws-right-margin, ${margins.right}px) var(--ws-bottom-margin, ${margins.bottom}px) var(--ws-left-margin, ${margins.left}px);
        }
    `;
    document.head.appendChild(style);
}

function toggleWorkspaceHighlight(isChecked) {
    if (isChecked) {
        // Toggle the highlight class on the body based on the checkbox state
        document.body.classList.add("highlight-workspace");
        // If we haven't already inserted divs to show the original workspace heights, do that now
        if (!document.querySelector('.workspace-container')) {
            console.log("adding original workspace divs");
            // Insert divs to show the original workspace
            document.querySelectorAll('.workspace').forEach(workspace => {
                // Create a container div to hold the workspace div and the original div
                const container = document.createElement('div');
                container.classList.add('workspace-container');
                // Deliberately no fixed height on the container.
                //
                // A height snapshotted here goes stale the moment
                // adjustWorkspaceToFitPage() resizes the workspace -- and
                // because flattenSolutionsIn() has already hoisted the
                // workspace out to be a top-level row, this container *is*
                // that row, so the stale value is what createPrintoutPages()
                // measures.  setInitialWorkspaceHeights() resets the
                // `.workspace` back to its authored height but knows nothing
                // about the wrapper, so pagination would plan against the
                // previous, stretched size, hand each page more slack than it
                // really has, and stretch the workspaces again -- a feedback
                // loop that made the whole layout depend on whether the
                // "highlight workspace" box happened to be ticked.
                //
                // Letting the container size to its content keeps it exactly
                // as tall as the workspace at all times, with no value to
                // synchronise.  The marker below is taken out of flow so that
                // it cannot contribute height either.
                container.style.position = 'relative';
                const original = document.createElement('div');
                original.classList.add('original-workspace');
                const originalHeight = workspace.getAttribute('data-space') || '0px';
                original.setAttribute('title', 'Author-specified workspace height (' + originalHeight + ')');
                // Use the data-space attribute for height of original workspace
                original.style.height = originalHeight;
                // Overlaid rather than laid out beside the workspace: it still
                // shows the authored height (overflowing visibly when that is
                // taller than what the workspace was squeezed to, which is the
                // point of the marker) without affecting the row's own height.
                original.style.position = 'absolute';
                original.style.top = '0';
                original.style.left = '0';
                // insert original div before the workspace content
                container.appendChild(original);
                // The container stands in for the workspace as a pagination
                // row while the overlay is on, so it has to carry the group
                // stamp too -- otherwise the question and its writing space
                // stop being seen as one unit.  See isWorkspaceRow().
                if (workspace.dataset.blockGroup) {
                    container.dataset.blockGroup = workspace.dataset.blockGroup;
                }
                // ...and, for the same reason, the indent that keeps a hoisted
                // workspace lined up with its task.  See moveDepthClass().
                moveDepthClass(workspace, container);
                // Move the workspace into the container
                workspace.parentNode.insertBefore(container, workspace);
                container.appendChild(workspace);
                // Flag the marker when the author asked for more room than the
                // workspace was ultimately given.  Measured only now that both
                // elements are actually in the document -- offsetHeight on a
                // detached node is always 0, so checking this before the insert
                // above (as this did previously) could never be true, and the
                // warning never appeared.
                if (original.offsetHeight > workspace.offsetHeight) {
                    original.classList.add('warning');
                }
            });
        }
    } else {
        document.body.classList.remove("highlight-workspace");
        // Remove the original workspace divs.  We don't want to keep these in, as they interfere with changing page sizes and workspace heights.
        document.querySelectorAll('.workspace-container').forEach(container => {
            const workspace = container.querySelector('.workspace');
            // The workspace is about to be the row again, so it takes the
            // indent back with the role.
            moveDepthClass(container, workspace);
            // Move the workspace out of the container
            container.parentNode.insertBefore(workspace, container);
            // Remove the container
            container.remove();
        });
    }
}

function getPaperSize() {
    let paperSize = localStorage.getItem("papersize");
    if (paperSize) {
      return paperSize;
    } else {
        // Try to set papersize based on user's geographic region
        // Default to 'letter' for North and South America, 'a4' elsewhere
        try {
          fetch('https://ipapi.co/json/')
            .then(response => response.json())
            .then(data => {
          let continent = data && data.continent_code ? data.continent_code : "";
          paperSize = (continent === "NA" || continent === "SA") ? "letter" : "a4";
          const radio = document.querySelector(`input[name="papersize"][value="${paperSize}"]`);
          if (radio) {
            radio.checked = true;
            localStorage.setItem("papersize", paperSize);
          }
          document.body.classList.remove("a4", "letter");
          document.body.classList.add(paperSize);
          console.log("Setting papersize to", paperSize);
            })
            .catch((err) => {
            // rethrow to be caught by the outer catch
            throw err;
            });
        } catch (e) {
          // fallback: default to letter
          const radio = document.querySelector(`input[name="papersize"][value="letter"]`);
          if (radio) radio.checked = true;
        }
    }
    return paperSize || "letter";
}

// A project-like born hidden as a knowl (the publisher's knowl-project) renders
// as
//   <details id="..."><summary><h2 class="heading"/><div class="print-links"/></summary>
//     <article class="knowl__content">...</article></details>
// so the id lands on the <details>, the title sits in the <summary>, and the
// content is a separate article with no title of its own.  Rebuild it as the
// single block a visible project would have produced, title first, so the rest
// of the preview needs to know nothing about knowls.  Returns the block to
// preview, or the <details> unchanged if it is not shaped as expected.
function flattenKnowledPrintout(details) {
    const content = details.querySelector(':scope > .knowl__content');
    if (!content) {
        console.warn("Born-hidden printout has no knowl content; previewing as-is:", details);
        return details;
    }
    const heading = details.querySelector(':scope > summary > .heading');
    if (heading) {
        content.insertBefore(heading, content.firstChild);
    }
    // It is the page now, not knowl content.  Carry the id over so the preview
    // keeps the identity named in the URL.
    content.classList.remove('knowl__content');
    content.id = details.id;
    // Moves content out of details, then drops the details (and its summary).
    details.replaceWith(content);
    return content;
}

// The print icon has to live inside the <summary> of a born-hidden knowl to be
// visible while the knowl is closed, but a click in a <summary> is the knowl's
// own open/close toggle.  So follow the link ourselves and swallow the toggle.
document.addEventListener("click", (ev) => {
    const link = ev.target.closest("a.print-link");
    if (!link || !link.closest("summary")) return;
    ev.preventDefault();
    ev.stopPropagation();
    window.location.assign(link.href);
});

// Function to load the printout section and switch to print stylesheet.  This will run whenever a user clicks on a print preview link (which adds ?printpreview=sectionID to the URL).
async function loadPrintout(printableSectionID) {

    // Switch to print-worksheet.css for print preview
    const themeStylesheetLink = document.querySelector('link[rel="stylesheet"][href*="theme"]');
    // get the href of the theme stylesheet link
    const themeStylesheetHref = themeStylesheetLink ? themeStylesheetLink.getAttribute('href') : null;
    if (themeStylesheetHref) {
        // replace 'theme.css' with 'print-worksheet.css' in the href
        const printStylesheetHref = themeStylesheetHref.replace(/theme.*\.css/, 'print-worksheet.css');
        // Swap stylesheets by replacing the <link> element rather than by
        // rewriting the href of the existing one.
        //
        // Everything below depends on the print stylesheet actually being in
        // force -- every height this file measures is measured under it -- so
        // the swap has to be waited on.  But Chromium does not fire "load" on a
        // link whose href is rewritten in place: the new stylesheet is fetched
        // and applied, and no event is ever dispatched, so waiting on one hangs
        // here forever and the preview is left as an unpaginated page.  A
        // freshly created element fires load, and error, reliably.
        //
        // The new link goes in alongside the old one and the old one comes out
        // only once the new one has loaded, so the preview is never briefly
        // unstyled.  Resolving on "error" too means a print stylesheet that is
        // missing or fails to fetch degrades to a preview styled by the theme,
        // rather than to no preview at all.
        const printStylesheetLink = document.createElement('link');
        printStylesheetLink.setAttribute('rel', 'stylesheet');
        printStylesheetLink.setAttribute('type', 'text/css');
        const stylesheetSettled = new Promise((resolve) => {
            printStylesheetLink.addEventListener('load', resolve, { once: true });
            printStylesheetLink.addEventListener('error', resolve, { once: true });
        });
        printStylesheetLink.setAttribute('href', printStylesheetHref);
        themeStylesheetLink.after(printStylesheetLink);
        await stylesheetSettled;
        themeStylesheetLink.remove();
    }

    // Find the element with this ID.  For a worksheet or handout this is the
    // division's section; for a standalone project-like printout it is the
    // project's article, nested somewhere inside a division section, or a
    // <details> if the project is born hidden as a knowl.
    let printableSection = document.getElementById(printableSectionID);
    if (!printableSection) {
        console.error("No printable element found with ID:", printableSectionID);
        return;
    }
    if (printableSection.tagName === "DETAILS") {
        printableSection = flattenKnowledPrintout(printableSection);
    }
    // Mark it as the printout so the stylesheet and the pagination code below
    // can find it without knowing which kind of element it is.
    printableSection.classList.add("printout");
    // Remove any existing sections from .ptx-content and add only the printable
    // section.  Removing a section that contains the printout is harmless: we
    // still hold a reference to it, and re-attach it on the next line.
    const ptxContent = document.querySelector('.ptx-content');
    const existingSections = ptxContent.querySelectorAll(':scope > section');
    existingSections.forEach(sec => ptxContent.removeChild(sec));
    ptxContent.appendChild(printableSection);
}

// Whether hint/answer/solution divs of `solutionType` should be hidden: the
// user's stored choice if there is one, otherwise the default (answers and
// solutions start hidden, hints don't). Single source of truth for that
// default so rewriteSolutions() (which needs it immediately, before the
// checkbox that owns it has even been set up) and the checkbox setup loop
// below can't drift apart.
function solutionTypeHidden(solutionType) {
    const stored = localStorage.getItem(`hide-${solutionType}`);
    if (stored !== null) {
        return stored === "true";
    }
    return solutionType === "answer" || solutionType === "solution";
}

// Function to redo solutions details to divs with summary as title
async function rewriteSolutions() {
    // A footnote is a <details> too, but it is not a knowl to be unfolded in
    // place: rebuildFootnotes() clones its text into a block at the foot of
    // whichever page the reference lands on, the way a book sets footnotes, and
    // only the marker stays inline.  Rewriting one here would instead drop its
    // number into the text as an <h5> heading and its contents as a bordered
    // box, in the middle of the sentence that referenced it.
    var born_hidden_knowls = document.querySelectorAll('.printout details:not(.ptx-footnote)');
    born_hidden_knowls.forEach(function(detail) {
        const summary = detail.querySelector('summary');
        const content = detail.innerHTML.replace(summary.outerHTML, '');
        const div = document.createElement('div');
        div.classList = detail.classList;
        // Unconditionally hidden here, regardless of the stored/default
        // preference for this solutionType: the very first pagination pass
        // needs one single, reproducible "everything hidden" starting point
        // to lay pages out against (see the DOMContentLoaded handler below,
        // where whichever types should actually start visible get revealed
        // afterward, through the same incremental show/hide path a checkbox
        // toggle uses). Basing initial layout on the *actual* visibility
        // instead would make that layout as reachable only from that one
        // specific combination of shown/hidden types, instead of from the
        // one common base every hide always returns to.
        for (const solutionType of ["hint", "answer", "solution"]) {
            if (div.classList.contains(solutionType)) {
                div.classList.add("hidden");
                break;
            }
        }
        if (summary) {
            const title = document.createElement('h5');
            title.innerHTML = summary.innerHTML;
            div.appendChild(title);
        }
        const body = document.createElement('div');
        body.innerHTML = content;
        div.appendChild(body);
        detail.parentNode.replaceChild(div, detail);
    });
    if (typeof MathJax !== "undefined" && MathJax.typesetPromise) {
        await MathJax.typesetPromise();
    }
}

// Utility to convert various CSS length units to pixels
function toPixels(value) {
    if (typeof value === "number") return value;
    if (typeof value !== "string") return 0;
    value = value.trim();
    if (value.endsWith("px")) {
        return parseFloat(value);
    } else if (value.endsWith("in")) {
        return Math.floor(parseFloat(value) * 96);
    } else if (value.endsWith("cm")) {
        return Math.floor(parseFloat(value) * 37.8);
    } else if (value.endsWith("mm")) {
        return Math.floor(parseFloat(value) * 3.78);
    } else if (value.endsWith("pt")) {
        return Math.floor(parseFloat(value) * (96 / 72));
    } else {
        // fallback: try to parse as px
        return parseFloat(value) || 0;
    }
}

// A cheap fingerprint of the current page layout: how many pages there are
// and each one's height. Good enough to tell "still changing" from "settled"
// without needing to know *why* something might still be resizing (MathJax,
// an image, a browser reflow after a class toggle, etc).
function pageLayoutSignature() {
    return [...document.querySelectorAll('.onepage')]
        .map(page => Math.round(page.getBoundingClientRect().height))
        .join(',');
}

// Repeatedly call `settle` (a synchronous pagination/layout pass) on an
// interval, stopping as soon as the page layout looks the same for
// `stableTicks` ticks in a row -- i.e. nothing is left to settle -- rather
// than always running for the full `timeoutMs` window. `timeoutMs` is a hard
// cap for content that can never fully converge (e.g. a single block
// permanently too tall for one page -- see addSpilloverPages()); without it,
// content still actively resizing (a solution knowl settling into its final
// size, a late-typesetting equation) could stop being watched too early.
//
// Without the early stop, `settle` -- which can call
// addHeadersAndFootersToPrintout(), destroying and recreating every
// header/footer contenteditable div -- would otherwise run unconditionally
// on every tick for the whole window, on every checkbox toggle, even long
// after nothing is actually still changing: wasted layout work at best, and
// at worst it yanks the cursor out from under someone mid-edit in a header
// or footer field.
async function pollUntilSettled(settle, {timeoutMs = 2000, intervalMs = 100, stableTicks = 3} = {}) {
    const deadline = Date.now() + timeoutMs;
    let lastSignature = null;
    let stableCount = 0;
    while (Date.now() < deadline) {
        await new Promise(r => setTimeout(r, intervalMs));
        settle();
        const signature = pageLayoutSignature();
        if (signature === lastSignature) {
            if (++stableCount >= stableTicks) return;
        } else {
            stableCount = 0;
            lastSignature = signature;
        }
    }
}

// Show or hide every div of `solutionType` and adjust pagination to match.
// Shared by the checkbox change handler and by the initial application of
// stored/default visibility right after the base layout is built, so both
// paths are guaranteed to behave identically.
//
// Always incremental -- addSpilloverPages()/collapseSpilloverPages() acting
// on the existing .onepage structure -- never a full recompute
// (resetPrintoutPagination()/createPrintoutPages()). The base layout (built
// with every hint/answer/solution hidden -- see rewriteSolutions()) assigns
// each row to a page exactly once; a full recompute after that would
// re-derive page breaks from whatever happens to be visible at the time,
// which depends on which other types happen to be shown, so a show/hide
// round trip on one type wasn't guaranteed to land back on the same layout
// it started from. Collapsing always folds back toward that one base, and
// showing only ever pushes overflow forward onto a new page, so hiding
// reliably undoes exactly what showing did.
//
// Runs under withIframesDetached() since the repagination and collapse work
// below can move a row -- and any iframe inside it -- several times over the
// course of one toggle.
async function applySolutionVisibility(solutionType, hidden, {paperSize, margins}) {
    document.querySelectorAll(`div.${solutionType}`).forEach(elem => {
        if (hidden) { elem.classList.add("hidden"); }
        else { elem.classList.remove("hidden"); }
    });
    await withIframesDetached(async () => {
        if (hidden) {
            collapseSpilloverPages(margins);
            adjustWorkspaceOrRepaginate({paperSize, margins, fullRecompute: false});
            // Content just hidden (e.g. a long solution) can take a moment to
            // finish settling into its final, compact size, so an immediate
            // measurement can miss a page that's actually able to collapse.
            await pollUntilSettled(() => {
                collapseSpilloverPages(margins);
                adjustWorkspaceOrRepaginate({paperSize, margins, fullRecompute: false});
            });
        } else {
            adjustWorkspaceOrRepaginate({paperSize, margins, fullRecompute: false});
            await pollUntilSettled(() => {
                if (pageOverflows()) {
                    addSpilloverPages(margins);
                    adjustWorkspaceToFitPage({paperSize, margins});
                }
            });
        }
    });
}

// Event listener for page load to handle print preview setup
window.addEventListener("DOMContentLoaded", async function(event) {
    const urlParams = new URLSearchParams(window.location.search);
    let pendingSettle = Promise.resolve();
    // We condition on the existence of the papersize radio buttons, which only appear in the printout print preview.
    if (urlParams.has("printpreview")) {
        const printableSectionID = urlParams.get("printpreview");
        await loadPrintout(printableSectionID);

        // loadPrintout bails out if the id names nothing printable (a stale or
        // hand-edited URL), so there may be no printout to lay out.
        const printout = getPrintout();
        if (!printout) {
            console.warn("Nothing to preview for printpreview=" + printableSectionID + "; leaving the page as it is.");
            return;
        }

        // If the printout has authored pages, there will be at least one .onepage
        // element. That's purely a property of the source HTML, so it's safe to
        // read this early, before anything below has a chance to touch the DOM.
        // Declared up here (rather than right before its first use, closer to
        // adjustPrintoutPages()) because the hide/reveal checkbox handlers set
        // up below close over it too, and a forward reference to a `const`
        // declared later in this same function only happens to work today
        // because those handlers can't fire before this function finishes
        // running -- moving it here removes that fragility outright.
        const hasAuthoredPages = document.querySelectorAll('.onepage').length > 0;

        // First, get the margins for pages to be passed around as needed.
        const marginList = (printout.getAttribute('data-margins') || "").split(' ');
        // Convert margin values to pixels if they are not already numbers
        const margins = {
            top: toPixels(marginList[0] || "0.75in"), // Default to 0.75in if not specified
            right: toPixels(marginList[1] || "0.75in"),
            bottom: toPixels(marginList[2] || "0.75in"),
            left: toPixels(marginList[3] || "0.75in")
        }

        // Transform all solutions details elements to divs with the summary as a title
        await rewriteSolutions();

        // Get the papersize from localStorage or set it based on user's geographic region.  This will always return a value (defaulting to 'letter' if all else fails).
        let paperSize = getPaperSize();
        if (paperSize) {
        const radio = document.querySelector(`input[name="papersize"][value="${paperSize}"]`);
        if (radio) {
            radio.checked = true;
        }
        // Set the papersize class on body
        document.body.classList.remove("a4", "letter");
        document.body.classList.add(paperSize);
        setPageGeometryCSS({paperSize: paperSize, margins: margins});
        } else {
            console.warn("Bug: paperSize should always have a value here.");
        }
        // Add event listeners to the papersize radio buttons to handle changes
        const papersizeRadios = document.querySelectorAll('input[name="papersize"]');
        papersizeRadios.forEach(radio => {
            radio.addEventListener('change', function() {
                if (this.checked) {
                    document.body.classList.remove("a4", "letter");
                    document.body.classList.add(this.value);
                    localStorage.setItem("papersize", this.value);
                    setPageGeometryCSS({paperSize: this.value, margins: margins});
                    adjustWorkspaceToFitPage({paperSize: this.value, margins: margins});
                }
            });
        });

        // Set up (but don't yet apply) the hide hints/answers/solutions
        // checkboxes. Actually showing whichever types should start visible
        // happens later, in one place, after the base layout (built with
        // everything hidden -- see rewriteSolutions()) is fully settled;
        // see the applySolutionVisibility() call near the end of this handler.
        for (const solutionType of ["hint", "answer", "solution"]) {
            const checkbox = document.getElementById(`hide-${solutionType}-checkbox`);
            if (!checkbox) continue;
            // The XSL only generates this checkbox at all if *some* worksheet
            // on the page has this type of content, since one print-preview
            // control panel can be shared by several worksheets (the one
            // actually shown is picked at runtime via ?printpreview=<id>).
            // Whether it applies to *this* worksheet specifically can only be
            // decided here, against the printout that actually got loaded --
            // if not, hide the whole row rather than leave a checkbox with
            // nothing for it to toggle.
            if (!printout.querySelector(`.${solutionType}`)) {
                const row = checkbox.closest('.hide-option');
                if (row) row.classList.add('hidden');
                continue;
            }
            const storageKey = `hide-${solutionType}`;
            checkbox.checked = solutionTypeHidden(solutionType);
            // Persist the default immediately (not just once the user
            // makes an explicit choice), so it's already on record the
            // next time anything -- e.g. rewriteSolutions() -- needs it.
            if (localStorage.getItem(storageKey) === null) {
                localStorage.setItem(storageKey, checkbox.checked ? "true" : "false");
            }
            checkbox.addEventListener("change", async function() {
                await pendingSettle;
                localStorage.setItem(storageKey, this.checked);
                pendingSettle = applySolutionVisibility(solutionType, this.checked, {paperSize, margins});
            });
        }
        // If none of the three applied to this worksheet, every row above
        // just got hidden -- also hide the now-empty group container so it
        // doesn't leave a stray gap in the print-options panel.
        const hideSolutionsOptions = document.querySelector('.hide-solutions-options');
        if (hideSolutionsOptions && !hideSolutionsOptions.querySelector('.hide-option:not(.hidden)')) {
            hideSolutionsOptions.classList.add('hidden');
        }

        // Finally, with everything set up, we create or adjust the printout pages as needed.

        // Flatten paragraphs sections so page breaks can occur inside them.
        const printoutSection = getPrintout();
        if (printoutSection) {
            flattenParagraphsSections(printoutSection);
        }

        // Wait for all images to load so height measurements are accurate.
        if (printoutSection) {
            await waitForImages(printoutSection);
        }

        // Add explicit await before initial pagination step so all math is settled before measuring content height.
        if (typeof MathJax !== "undefined" && MathJax.typesetPromise) {
            await MathJax.typesetPromise([getPrintout()]);
        }

        // hasAuthoredPages (computed above) picks the right strategy here:
        // preserve authored structure vs. safely recompute a computed layout.
        if (hasAuthoredPages) {
            adjustPrintoutPages(margins);
        } else {
            createPrintoutPages(margins);
            // Safety net: content heights (e.g. proof knowls, large matrices) can
            // still be settling into their final size at this point, which can
            // cause createPrintoutPages to make suboptimal page-break decisions
            // that don't overflow but leave large amounts of wasted space. Since
            // that failure mode isn't detectable via pageOverflows(), just
            // unconditionally re-run pagination once more after a brief settle delay.
            // Tracked via pendingSettle so any checkbox toggle that happens in the
            // meantime waits for this to finish first, instead of racing it.
            pendingSettle = (async () => {
                await new Promise(r => setTimeout(r, 300));
                unwrapOnepages();
                createPrintoutPages(margins);
                addHeadersAndFootersToPrintout();
                adjustWorkspaceToFitPage({paperSize: paperSize, margins: margins});
            })();
        }

        // Add headers and footers to all pages in the printout
        addHeadersAndFootersToPrintout();

        // Add event listeners to the print header/footer checkboxes
        for (const hf of ["first-page-header", "running-header", "first-page-footer", "running-footer"]) {
            const checkbox = document.getElementById(`print-${hf}-checkbox`);
            if (checkbox) {
                // set visibility based on current checkbox state
                checkbox.checked = localStorage.getItem(`print-${hf}`) === "true";
                document.querySelectorAll(`.${hf}`).forEach(elem => {
                    // add hidden to class list
                    if (checkbox.checked) {
                        elem.classList.remove("hidden");
                    } else {
                        elem.classList.add("hidden");
                    }
                });
                // Add event listener to toggle visibility
                checkbox.addEventListener("change", function() {
                    localStorage.setItem(`print-${hf}`, this.checked);
                    // toggle visibility of header/footer divs
                    document.querySelectorAll(`.${hf}`).forEach(elem => {
                        if (checkbox.checked) {
                            elem.classList.remove("hidden");
                        } else {
                            elem.classList.add("hidden");
                        }
                    });
                    // Recompute layout once, after all elements of this type have been toggled
                    adjustWorkspaceToFitPage({paperSize: paperSize, margins: margins});
                });
            }
        }

        // After pages are set up, we adjust the workspace heights to fit the page (based on the paper size),
        // falling back to a spillover page if content still overflows even with workspace at zero.
        adjustWorkspaceOrRepaginate({paperSize: paperSize, margins: margins, fullRecompute: !hasAuthoredPages});
        // Chain onto pendingSettle (rather than overwrite it) so this loop waits
        // for the non-authored-pages safety net scheduled above, if one was
        // scheduled, to finish first. Overwriting it would silently orphan that
        // safety net's promise -- it would still fire on its own timer and mutate
        // the printout unsynchronized with this loop and with whatever a checkbox
        // toggled in the meantime is doing, despite the whole point of
        // pendingSettle being to let a checkbox toggle await "settling in
        // progress" as a single, serialized thing.
        pendingSettle = pendingSettle.then(() => pollUntilSettled(() => {
            if (hasAuthoredPages) {
                // Content still settling into its final size right after
                // load (e.g. a solution knowl, an embedded matrix) can make
                // the very first pass above split content onto a spillover
                // page it doesn't actually need once things settle down.
                // Eagerly try collapsing spillover pages back on every tick
                // and let addSpilloverPages() re-split only what still
                // doesn't fit -- see collapseSpilloverPages()'s comment for
                // why collapsing first, unconditionally, is the reliable order.
                collapseSpilloverPages(margins);
                adjustWorkspaceOrRepaginate({paperSize: paperSize, margins: margins, fullRecompute: false});
            } else if (pageOverflows()) {
                resetPrintoutPagination(margins);
                adjustWorkspaceToFitPage({paperSize: paperSize, margins: margins});
            }
        }));

        // Now that the base layout (built with every hint/answer/solution
        // hidden -- see rewriteSolutions()) has fully settled, reveal
        // whichever types should actually start visible per their stored/
        // default preference, through the same incremental path a checkbox
        // toggle uses. Chained onto pendingSettle so this waits for that
        // settling to finish first -- revealing against a layout that's
        // still being rebuilt out from under it would be measuring against
        // a moving target -- and so a checkbox click in the meantime waits
        // for this in turn, rather than raced against it.
        pendingSettle = pendingSettle.then(async () => {
            for (const solutionType of ["hint", "answer", "solution"]) {
                if (printout.querySelector(`.${solutionType}`) && !solutionTypeHidden(solutionType)) {
                    await applySolutionVisibility(solutionType, false, {paperSize, margins});
                }
            }
        });

        // Get the 'highlight workspace' checkbox state from localStorage or set it to false by default
        // NB we need to do this after the adjustment of workspace heights so that the additional original workspace divs don't throw off the calculations when the page is reloaded.
        const highlightWorkspaceCheckbox = document.getElementById("highlight-workspace-checkbox");
        if (highlightWorkspaceCheckbox) {
            // Same reasoning as the hide-hint/answer/solution rows above: this
            // control panel can be shared by several worksheets on the same
            // page, so whether this worksheet actually has any workspace to
            // highlight can only be decided here, against the printout that
            // actually got loaded.
            if (workspaceDivsIn(printout).length === 0) {
                const row = highlightWorkspaceCheckbox.closest('.highlight-workspace-option');
                if (row) row.classList.add('hidden');
            } else {
                highlightWorkspaceCheckbox.checked = localStorage.getItem("highlightWorkspace") === "true";
                highlightWorkspaceCheckbox.addEventListener("change", function() {
                    localStorage.setItem("highlightWorkspace", this.checked);
                    toggleWorkspaceHighlight(this.checked);
                });
                // Initial toggle to apply the highlight class if checked
                toggleWorkspaceHighlight(highlightWorkspaceCheckbox.checked);
            }
        }

        console.log("finished adjusting workspace");
    }
});
