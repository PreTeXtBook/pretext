// Import/export the contents of Sage code cells as a JSON file.
//
// Each cell is a "div.ptx-sagecell" with the stable id PreTeXt itself
// assigns (from the source's xml:id, or a generated one). SageMathCell's
// own runtime JavaScript (loaded externally, not part of this repo) adds
// an "output_<hex>" class to that same div once it initializes the cell --
// but that hex string is a fresh random id generated on every page load,
// not something that survives a reload, so it can't be used as an export
// key. The PreTeXt id is what's stable, so the exported/imported JSON is
// keyed by that. Only the *code* currently in a cell's editor is touched,
// never its evaluated output.

// CodeMirror 5 (what SageMathCell embeds) exposes the editor instance as a
// ".CodeMirror" property on the wrapper element it builds, nested inside
// the "div.ptx-sagecell" alongside the eval button and output area.
function findCodeMirror(container) {
    const wrapper = container.querySelector(".CodeMirror");
    return wrapper ? wrapper.CodeMirror : null;
}

function collectCodeCells() {
    const cells = {};
    document.querySelectorAll(".ptx-sagecell").forEach((el) => {
        const cm = findCodeMirror(el);
        if (cm) {
            cells[el.id] = cm.getValue();
        }
    });
    return cells;
}

function exportCodeCells(statusElement) {
    const cells = collectCodeCells();
    const count = Object.keys(cells).length;
    if (count === 0) {
        statusElement.textContent = "No code cells found on this page.";
        return;
    }
    const blob = new Blob([JSON.stringify(cells, null, 2)], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = "code-cells.json";
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
    statusElement.textContent = "Exported " + count + " code cell" + (count === 1 ? "" : "s") + ".";
}

function importCodeCells(file, statusElement) {
    const reader = new FileReader();
    reader.onload = () => {
        let cells;
        try {
            cells = JSON.parse(reader.result);
        } catch (err) {
            statusElement.textContent = "Could not read that file: not valid JSON.";
            return;
        }
        let updated = 0;
        let missing = 0;
        for (const [id, code] of Object.entries(cells)) {
            const container = document.getElementById(id);
            const cm = container ? findCodeMirror(container) : null;
            if (cm) {
                cm.setValue(code);
                updated += 1;
            } else {
                missing += 1;
            }
        }
        if (updated === 0) {
            statusElement.textContent = "No matching code cells found on this page.";
        } else if (missing === 0) {
            statusElement.textContent = "Updated " + updated + " code cell" + (updated === 1 ? "" : "s") + ".";
        } else {
            statusElement.textContent = "Updated " + updated + " code cell" + (updated === 1 ? "" : "s") + "; " + missing + " not found on this page.";
        }
    };
    reader.onerror = () => {
        statusElement.textContent = "Could not read that file.";
    };
    reader.readAsText(file);
}

window.addEventListener("DOMContentLoaded", function () {
    const codeButton = document.getElementById("ptx-code-cells-button");
    const codePopup = document.getElementById("ptx-code-cells-popup");
    if (!codeButton || !codePopup) {
        return;
    }

    new PTXDialog(codePopup, codeButton, {
        kind: "light-close",
        closeButton: document.getElementById("ptx-code-cells-close-button")
    });

    const statusElement = document.getElementById("ptx-code-cells-status");
    const importInput = document.getElementById("ptx-code-cells-import-input");

    const exportButton = document.getElementById("ptx-code-cells-export-button");
    if (exportButton) {
        exportButton.addEventListener("click", () => exportCodeCells(statusElement));
    }

    const importButton = document.getElementById("ptx-code-cells-import-button");
    if (importButton && importInput) {
        importButton.addEventListener("click", () => importInput.click());
        importInput.addEventListener("change", () => {
            const file = importInput.files[0];
            if (file) {
                importCodeCells(file, statusElement);
            }
            importInput.value = "";
        });
    }
});
