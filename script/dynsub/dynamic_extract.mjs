// Evaluate the setup of every dynamic exercise once, with a fixed seed,
// and record the resulting substitutions for use by static conversions.
//
// The hard requirement here is fidelity: a value this script produces has to
// be the value the Runestone component would have produced in a browser for
// the same seed.  So the way an exercise's libraries are imported, the way
// their exports are brought into scope, and the shape of the function the
// setup runs inside all deliberately mirror the component.

// Node style of import
import { RNG } from 'btm-expressions/src/random.js';
import { readFileSync, writeFileSync, mkdirSync, realpathSync } from 'node:fs';
import { pathToFileURL } from 'node:url';
import { dirname, join, relative, resolve } from 'node:path';
import { parseArgs } from 'node:util';

// Deno style of import
// import { readFileSync,writeFileSync } from "node:fs";
// import { RNG } from "npm:btm-expressions/src/random.js";
// import { parseArgs } from "jsr:@std/cli/parse-args";

// Node parse arguments
const {
  values: { input, output, basedir },
} = parseArgs({
  options: {
    input: {
      type: "string",
      short: "i",
    },
    output: {
      type: "string",
      short: "o",
    },
    // Directory that project-local library paths are relative to.  The
    // paths in the JSON begin with the external directory as written for
    // HTML (e.g. "external/code/lib.js"), so this is whatever directory
    // the external tree was copied into for the build.
    basedir: {
      type: "string",
      short: "b",
    },
  },
});
const args = { input: input, output: output, basedir: basedir };

// Deno parse arguments
// const args = parseArgs(Deno.args, {
//     string: ["input", "output", "basedir"]
// });

const baseDirectory = args.basedir ? resolve(args.basedir) : dirname(resolve(args.input));

// Report in the same vocabulary the XSL stylesheets use, so that a problem
// here reads like every other build message the author sees.
const errors = [];
const reportError = function (message) {
    errors.push(message);
    console.error("PTX:ERROR:   " + message);
};
const reportWarning = function (message) {
    console.error("PTX:WARNING:   " + message);
};

// Exit codes.  The script always tries to leave a usable substitutions file
// behind, so the code says how much to trust what was written rather than
// simply whether the run was happy.  pretext.py  branches on these.
const EXIT_OK = 0;             // every substitution was evaluated
const EXIT_PLACEHOLDERS = 1;   // file is usable, but some entries are markers
const EXIT_NO_FILE = 2;        // nothing usable could be written at all

// Version stamped on the root of the substitutions file.
// v 1: "eval-subst" has "latex" and "plain" children,
// possibly containing an error marker if not generated.
// Files written before this existed have no @version (infer v 0) and hold text directly
const SUBSTITUTIONS_FORMAT_VERSION = "1";

// ---------------------------------------------------------------------------
// XML output
// ---------------------------------------------------------------------------

// Values reaching this file are arbitrary strings, and LaTeX in particular is
// full of characters XML reserves.  A matrix alone is enough to matter: an
// aligned row is joined with " & ", which without escaping produces a file
// that is not well-formed and cannot be read back at all.
const escapeXmlText = function (text) {
    return String(text)
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;");
};

const escapeXmlAttribute = function (text) {
    return escapeXmlText(text).replace(/"/g, "&quot;");
};

// ---------------------------------------------------------------------------
// Scope construction
// ---------------------------------------------------------------------------

// Names that cannot be function parameters.  "default" is the one that
// matters in practice: a module namespace object carries its default export
// under that key, so any library written with "export default" would
// otherwise produce a SyntaxError when its exports are spread into the
// parameter list.  The Runestone component has the same exposure.
const RESERVED_WORDS = new Set([
    "arguments", "await", "break", "case", "catch", "class", "const",
    "continue", "debugger", "default", "delete", "do", "else", "enum",
    "eval", "export", "extends", "false", "finally", "for", "function",
    "if", "implements", "import", "in", "instanceof", "interface", "let",
    "new", "null", "package", "private", "protected", "public", "return",
    "static", "super", "switch", "this", "throw", "true", "try", "typeof",
    "var", "void", "while", "with", "yield",
]);

const IDENTIFIER = /^[A-Za-z_$][A-Za-z0-9_$]*$/;

const usableNames = function (obj) {
    return Object.keys(obj).filter(
        (key) => IDENTIFIER.test(key) && !RESERVED_WORDS.has(key)
    );
};

// ---------------------------------------------------------------------------
// Library imports
// ---------------------------------------------------------------------------

// Modules are cached by the specifier that appears in the JSON import
// path, so a library shared by several exercises is fetched only once
// per run.  The cache is just this process's memory, so nothing
// persists between separate runs of the script.
const moduleCache = new Map();

// All proposed external libraries are judged once for whether to import them.
// Use an allowlist of schemes. Only "https" is  permitted now, and everything else is rejected.
// Local files can be referenced relative to the project's external directory.
const SCHEME = /^([A-Za-z][A-Za-z0-9+.-]*):/;

const SPECIFIER_BTM = "btm";
const SPECIFIER_LOCAL = "local";
const SPECIFIER_REMOTE = "remote";
const SPECIFIER_BLOCKED_SCHEME = "blocked-scheme";
const SPECIFIER_PROTOCOL_RELATIVE = "protocol-relative";
const SPECIFIER_OFF_PROJECT = "off-project";

// Does a path land inside the directory the build resolves against?
//
// --basedir is the build's notion of the project root: pretext.py copies the
// external tree into it, and a specifier arrives carrying the "external/"
// prefix itself, which is what makes it the same relative string HTML uses.
// Only files that resolve inside this will be accessible.
//
// Resolve the path lexically first.  Then, if the target actually exists,
// resolve it again through realpathSync, which follows symlinks: a symlink
// planted inside the copied external tree but pointing outside it would
// otherwise pass the lexical check while reading a file the project does
// not own.  A specifier that does not exist yet (an author's typo, most
// likely) has no symlink to resolve, so it falls back to the lexical
// answer and is left for the ordinary "file not found" error to report.
const withinProject = function (specifier) {
    const lexical = relative(baseDirectory, resolve(baseDirectory, specifier));
    if (lexical === "" || lexical.startsWith("..")) {
        return false;
    }
    try {
        const realBase = realpathSync(baseDirectory);
        const realTarget = realpathSync(resolve(baseDirectory, specifier));
        const real = relative(realBase, realTarget);
        return real !== "" && !real.startsWith("..");
    } catch {
        // Nothing on disk yet at this path; the lexical check already
        // passed, so let the actual import attempt report what is wrong.
        return true;
    }
};

const classifySpecifier = function (specifier) {
    if (specifier === "BTM") {
        // Matched as a literal, exactly as the Runestone component does, so
        // that the expression library resolves to the installed package
        // rather than to some path relative to the project.  This is tested
        // first because "BTM" carries no scheme and would otherwise look like
        // a project-local path.
        return SPECIFIER_BTM;
    }
    if (specifier.startsWith("//")) {
        // No scheme, yet not local either. Browser and Node would treat
        // differently. Require explicit scheme or simplified relative path.
        return SPECIFIER_PROTOCOL_RELATIVE;
    }
    const scheme = SCHEME.exec(specifier);
    if (!scheme) {
        return withinProject(specifier) ? SPECIFIER_LOCAL : SPECIFIER_OFF_PROJECT;
    }
    if (scheme[1].toLowerCase() === "https") {
        return SPECIFIER_REMOTE;
    }
    return SPECIFIER_BLOCKED_SCHEME;
};

// Remote source is written to disk and imported as a file rather than handed
// to import(). The .mjs extension is deliberate: it forces Node to parse the file
// as an ES module so that import behaves like the browser would treat it.
//
// An approved host that stops responding must not hang the build silently;
// a bounded wait fails loudly instead.
const REMOTE_FETCH_TIMEOUT_MS = 30_000;
let remoteCount = 0;
const fetchRemoteModule = async function (url) {
    let response;
    try {
        response = await fetch(url, { signal: AbortSignal.timeout(REMOTE_FETCH_TIMEOUT_MS) });
    } catch (err) {
        if (err.name === "TimeoutError") {
            throw new Error(
                `request for ${url} did not respond within ${REMOTE_FETCH_TIMEOUT_MS / 1000}s`
            );
        }
        throw err;
    }
    if (!response.ok) {
        throw new Error(`request for ${url} returned ${response.status} ${response.statusText}`);
    }
    const source = await response.text();
    const remoteDirectory = join(baseDirectory, "_remote_libraries");
    mkdirSync(remoteDirectory, { recursive: true });
    remoteCount += 1;
    const filename = join(remoteDirectory, `library-${remoteCount}.mjs`);
    writeFileSync(filename, source, "utf8");
    return import(pathToFileURL(filename).href);
};

const importLibrary = async function (specifier) {
    if (moduleCache.has(specifier)) {
        return moduleCache.get(specifier);
    }
    const kind = classifySpecifier(specifier);
    let pending;
    if (kind === SPECIFIER_BTM) {
        pending = import("btm-expressions/src/BTM_root.js");
    } else if (kind === SPECIFIER_REMOTE) {
        pending = fetchRemoteModule(specifier);
    } else if (kind === SPECIFIER_LOCAL) {
        pending = import(pathToFileURL(resolve(baseDirectory, specifier)).href);
    } else {
        // Unreachable by way of main(): the pre-flight pass refuses every
        // specifier of any other kind before a single library is loaded, and
        // an exercise naming one is never imported or evaluated.
        // Kept as a guard, and deliberately a throw rather than a report:
        // a caller that skipped the pre-flight should fail loudly here.
        throw new Error(
            `the library specifier "${specifier}" is not one this script will load`
        );
    }
    moduleCache.set(specifier, pending);
    return pending;
};

// Combine the namespace objects into the single object whose keys become the
// names in scope.  Object.assign means a later library shadows an earlier one
// silently; that is the component's behavior and is preserved on purpose.
const importScope = async function (specifiers) {
    const namespaces = await Promise.all(specifiers.map(importLibrary));
    return Object.assign({}, ...namespaces);
};

// ---------------------------------------------------------------------------
// Evaluation
// ---------------------------------------------------------------------------

// Run an exercise's setup.  This is the Runestone component's call, with the
// same parameters, the same body wrapper, and the same strict-mode directive.
const runSetup = function (setup, seed, scope) {
    const names = usableNames(scope);
    const values = names.map((name) => scope[name]);
    const rng = new RNG({ seed: seed });
    const setupFunction = new Function(
        "v",
        "rand",
        ...names,
        `"use strict";\n${setup};\nreturn v;`
    );
    return setupFunction({}, rng.rand, ...values);
};

// Evaluate each substitution in the scope the setup left behind.
//
// An @obj is a Javascript expression and not just a variable name -- the HTML
// version drops the identical string into a template as [%= ... %] -- so
// something like "_config.date" has to be evaluated rather than looked up.
// Each expression is evaluated inside its own try/catch so that one bad
// reference costs only its own substitution.
const runEvaluations = function (expressions, dynamicVariables, scope) {
    const varNames = usableNames(dynamicVariables);
    const varValues = varNames.map((name) => dynamicVariables[name]);
    // A setup may well name one of its objects after the library function
    // that built it -- "rrefMatrix" holding the result of rrefMatrix() -- and
    // a repeated parameter name is an outright error under strict mode.  The
    // object the setup created wins, since that is what an @obj naming it is
    // asking for.
    const shadowed = new Set(varNames);
    const importNames = usableNames(scope).filter((name) => !shadowed.has(name));
    const importValues = importNames.map((name) => scope[name]);
    const guarded = expressions.map(
        (expression) =>
            `(function () { try { return { ok: true, value: (${expression}) }; }` +
            ` catch (e) { return { ok: false, error: String(e) }; } })()`
    );
    const evaluationFunction = new Function(
        ...varNames,
        ...importNames,
        `"use strict";\nreturn [\n${guarded.join(",\n")}\n];`
    );
    return evaluationFunction(...varValues, ...importValues);
};

// The two representations every substitution carries.  A static conversion
// picks between them by context: a reference inside "m" wants LaTeX, one in
// running prose wants the plain form, and the answer of a "fillin" wants
// whichever its @mode calls for.  Deciding here rather than at the point of
// use would mean guessing, and one object is commonly referenced both ways.
const renderLaTeX = function (value, scope) {
    if (typeof scope.toTeX === "function") {
        return scope.toTeX(value);
    }
    if (value !== null && value !== undefined && typeof value.toTeX === "function") {
        return value.toTeX();
    }
    return String(value);
};

const renderPlain = function (value) {
    return String(value);
};

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

const substitutionElement = function (object, latex, plain) {
    return (
        `    <eval-subst obj="${escapeXmlAttribute(object)}">` +
        `<latex>${escapeXmlText(latex)}</latex>` +
        `<plain>${escapeXmlText(plain)}</plain>` +
        `</eval-subst>\n`
    );
};

// What stands in for a substitution that could not be produced, whatever the
// reason -- a refused specifier, a library that would not load, a setup that
// threw, an expression that could not be evaluated or rendered.
//
// A marker rather than nothing at all.  An empty substitution leaves a blank
// in the finished book, which an author may never notice; a bracketed error
// is visible at exactly the place that needs attention, and it travels with
// the build instead of scrolling past in a log.
//
// The LaTeX form wraps the marker in "\hbox" because a substitution is often
// referenced from inside "m", and the marker is prose, not mathematics: bare,
// it would be typeset as a run of italic letters with the spaces discarded.
// "\hbox" is a TeX primitive, legal in math mode, and needs no package.  The
// marker itself contains no character LaTeX treats specially, so there is
// nothing further to escape.
const FAILED_PLAIN = "[ERROR generating substitution]";
const FAILED_LATEX = `\\hbox{${FAILED_PLAIN}}`;

const failedSubstitution = function (expression) {
    return substitutionElement(expression, FAILED_LATEX, FAILED_PLAIN);
};

// An exercise that could not be evaluated still gets an entry, with each of
// its substitutions carrying the marker.  Omitting the entry would leave the
// assembly stylesheet looking up an element that does not exist, which fails
// in a way that has nothing to do with the actual problem.
const failedExercise = function (identifier, expressions) {
    let element = `  <dynamic-substitution id="${escapeXmlAttribute(identifier)}">\n`;
    for (const expression of expressions) {
        element += failedSubstitution(expression);
    }
    element += "  </dynamic-substitution>\n";
    return element;
};

// Name an exercise the way its author would look for it.  @unique-id is what
// the author can search for, whether generated or based on label; the assembly id is what the
// substitutions file is keyed by and what other messages in the build use.
// Both are given when both exist, so neither the author nor anyone reading a
// log has to guess which identifier is being quoted.
const exerciseName = function (problem) {
    if (problem.exercise_unique_id) {
        return `"${problem.exercise_unique_id}" (assembly id: ${problem.exercise_id})`;
    }
    return `(assembly id: ${problem.exercise_id})`;
};

const processExercise = async function (problem, refusedSpecifier) {
    // Duplicate references to one object are expected and collapse here.
    const expressions = [...new Set(problem.exercise_evals || [])];
    const name = exerciseName(problem);

    // The pre-flight pass has already reported why, naming the specifier and
    // every exercise that asked for it.  Nothing of this exercise is imported
    // or run: the point of refusing a specifier is that its code does not
    // execute.  Its substitutions become markers and the document continues.
    if (refusedSpecifier !== undefined) {
        return failedExercise(problem.exercise_id, expressions);
    }

    let scope;
    let dynamicVariables;
    try {
        scope = await importScope(problem.exercise_imports || ["BTM"]);
    } catch (err) {
        reportError(
            `dynamic exercise ${name} could not load a library it imports, so its ` +
            `content cannot be generated for static output.  ${err.message || err}`
        );
        return failedExercise(problem.exercise_id, expressions);
    }

    try {
        dynamicVariables = runSetup(problem.exercise_setup, problem.exercise_seed, scope);
    } catch (err) {
        reportError(
            `the setup of dynamic exercise ${name} failed, so its content cannot be ` +
            `generated for static output.  ${err.message || err}`
        );
        return failedExercise(problem.exercise_id, expressions);
    }

    let results;
    try {
        results = runEvaluations(expressions, dynamicVariables, scope);
    } catch (err) {
        reportError(
            `the substitutions of dynamic exercise ${name} could not be evaluated.  ` +
            `${err.message || err}`
        );
        return failedExercise(problem.exercise_id, expressions);
    }

    let element = `  <dynamic-substitution id="${escapeXmlAttribute(problem.exercise_id)}">\n`;
    expressions.forEach(function (expression, index) {
        const result = results[index];
        if (!result.ok) {
            reportError(
                `dynamic exercise ${name} refers to "${expression}", which could not ` +
                `be evaluated, so that substitution is marked in the output.  ${result.error}`
            );
            element += failedSubstitution(expression);
            return;
        }
        if (result.value === undefined) {
            reportWarning(
                `dynamic exercise ${name} refers to "${expression}", which is ` +
                `undefined after the setup runs.  Check the spelling and that the ` +
                `setup assigns it.`
            );
        }
        try {
            element += substitutionElement(
                expression,
                renderLaTeX(result.value, scope),
                renderPlain(result.value)
            );
        } catch (err) {
            reportError(
                `dynamic exercise ${name} produced a value for "${expression}" that ` +
                `could not be rendered, so that substitution is marked in the output.  ` +
                `${err.message || err}`
            );
            element += failedSubstitution(expression);
        }
    });
    element += "  </dynamic-substitution>\n";
    return element;
};

// ---------------------------------------------------------------------------
// Pre-flight
// ---------------------------------------------------------------------------

// Every library specifier in the document is judged before any one of them is
// loaded and before any setup runs.  Two reasons for settling this up front
// rather than at the point of import.  The author sees every specifier that
// needs attention in a single build, instead of fixing one and discovering
// the next on the following build.  And no library executes while some other
// exercise in the same document is still holding a specifier nobody has
// reviewed -- which matters, because a static build runs this code under Node
// with the privileges of whoever is building, unsandboxed, a different
// proposition from the same code running in a reader's browser.
//
// Returns a map from exercise id to the specifier that got it refused.  An
// exercise in that map is not imported and not evaluated; its substitutions
// become markers, and the rest of the document is unaffected.
const preflightImports = function (exercises, allowed) {
    const approved = new Set(allowed || []);
    // Each maps a specifier to the exercises that named it.  Kept apart
    // because each asks the author for a different thing.
    const blocked = new Map();
    const schemeless = new Map();
    const offProject = new Map();
    const unapproved = new Map();
    const refused = new Map();

    const note = function (bucket, specifier, problem) {
        if (!bucket.has(specifier)) {
            bucket.set(specifier, []);
        }
        bucket.get(specifier).push(exerciseName(problem));
        refused.set(problem.exercise_id, specifier);
    };

    for (const problem of exercises) {
        if (!problem.exercise_id) {
            continue;
        }
        for (const specifier of problem.exercise_imports || []) {
            const kind = classifySpecifier(specifier);
            if (kind === SPECIFIER_BLOCKED_SCHEME) {
                note(blocked, specifier, problem);
            } else if (kind === SPECIFIER_PROTOCOL_RELATIVE) {
                note(schemeless, specifier, problem);
            } else if (kind === SPECIFIER_OFF_PROJECT) {
                note(offProject, specifier, problem);
            } else if (kind === SPECIFIER_REMOTE && !approved.has(specifier)) {
                note(unapproved, specifier, problem);
            }
        }
    }

    const listUsers = function (bucket) {
        return [...bucket]
            .map(([specifier, users]) =>
                `    ${specifier}\n        imported by: ${users.join("\n                     ")}`)
            .join("\n");
    };

    if (blocked.size > 0) {
        reportError(
            "a dynamic exercise imports a library through a scheme this script will\n" +
            "not load.  A specifier with no scheme is a path within the project; the\n" +
            "only other form accepted is a secure remote url beginning \"https://\".\n" +
            "\"http://\" in particular is never accepted and cannot be approved: a\n" +
            "static build runs an imported library on this machine, and source\n" +
            "fetched over a channel that is neither authenticated nor private is not\n" +
            "something to hand to that.  Correct these in the source:\n" +
            "\n" +
            listUsers(blocked) + "\n"
        );
    }

    if (schemeless.size > 0) {
        reportError(
            "a dynamic exercise imports a library by a url with no scheme, beginning\n" +
            "\"//\".  A browser reads that as remote and takes the protocol from the\n" +
            "page it is running in; a build has no page to take one from.  Write the\n" +
            "url out in full, beginning \"https://\":\n" +
            "\n" +
            listUsers(schemeless) + "\n"
        );
    }

    if (offProject.size > 0) {
        reportError(
            "a dynamic exercise imports a library by a path that leads outside the\n" +
            "project.  A project-local library has to be kept within the project's\n" +
            "own external directory, so that it is copied alongside the book and\n" +
            "served with it: that is the only way a reader's browser can load it.\n" +
            "A path reaching elsewhere on the machine building the book would work\n" +
            "here and leave the exercise broken in HTML.  Move the library into the\n" +
            "project's external directory and refer to it from there:\n" +
            "\n" +
            listUsers(offProject) + "\n"
        );
    }

    if (unapproved.size > 0) {
        reportError(
            "a static build has to run the Javascript libraries that dynamic\n" +
            "exercises import, under Node, on this machine.  Libraries loaded from\n" +
            "the internet are therefore not run unless the publisher file approves\n" +
            "each one by name.  Add the following to the publisher file, which is a\n" +
            "statement that you have satisfied yourself the code is safe to execute:\n" +
            "\n" +
            "    <dynamics>\n" +
            "        <remote-libraries>\n" +
            [...unapproved.keys()]
                .map((url) => `            <library url="${url}"/>`)
                .join("\n") +
            "\n" +
            "        </remote-libraries>\n" +
            "    </dynamics>\n" +
            "\n" +
            listUsers(unapproved) + "\n"
        );
    }

    return refused;
};

const main = async function () {
    let document;
    try {
        document = JSON.parse(readFileSync(args.input, "utf8"));
    } catch (err) {
        console.error(
            `PTX:ERROR:   the dynamic exercise setup file could not be read.  ${err.message || err}`
        );
        process.exitCode = EXIT_NO_FILE;
        return;
    }

    // The file was once a bare array of exercises.  Accept that shape too, so
    // a stale generated file does not become a hard failure.
    const exercises = Array.isArray(document) ? document : document.exercises || [];
    const allowed = Array.isArray(document) ? [] : document.allowed_remote || [];

    // Judged for the whole document first.  Nothing below this line imports a
    // specifier that did not pass.
    const refused = preflightImports(exercises, allowed);

    let xmlResponse = `<xml version="${SUBSTITUTIONS_FORMAT_VERSION}">\n`;
    for (const problem of exercises) {
        if (!problem.exercise_id) {
            continue;
        }
        xmlResponse += await processExercise(problem, refused.get(problem.exercise_id));
    }
    xmlResponse += "</xml>";

    // The file is written whatever happened above.  A build that cannot
    // produce one substitution should still produce a book: assembly looks
    // these up with document(), so a missing file fails in a way that has
    // nothing to do with the actual problem, and every exercise in the
    // document loses its content rather than the one that is broken.
    try {
        writeFileSync(args.output, xmlResponse, "utf8");
    } catch (err) {
        console.error(
            `PTX:ERROR:   the dynamic substitutions file could not be written.  ${err.message || err}`
        );
        process.exitCode = EXIT_NO_FILE;
        return;
    }

    // Anything reported above leaves markers in the output rather than values.
    // The file remains well-formed and usable for every exercise that did
    // work, so this is not a failed run -- but it is not a clean one either,
    // and the exit code has to say which so that pretext.py can carry on and
    // still tell the author something needs fixing.
    if (errors.length > 0) {
        console.error(
            `PTX:ERROR:   ${errors.length} problem(s) occurred generating dynamic ` +
            `substitutions.  The affected substitutions read "${FAILED_PLAIN}" ` +
            `in static output.`
        );
        process.exitCode = EXIT_PLACEHOLDERS;
        return;
    }
    process.exitCode = EXIT_OK;
};

await main();
