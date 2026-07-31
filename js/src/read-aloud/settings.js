/*******************************************************************************
 * settings.js — voice / rate / scroll / continue persistence, dialog controls
 *******************************************************************************
 * Mirrors the readability-options.js patterns: values live in localStorage,
 * controls sit in the readability dialog (XSL emits them when the read-aloud
 * publication option is on), and this module keeps both in sync.
 *
 * The voice picker is populated from speechSynthesis.getVoices(), which is
 * empty until the voiceschanged event fires on Chrome — so population runs
 * both immediately and on that event.  Voices are filtered to the document
 * language (decision #9), falling back to the full list when nothing matches.
 ******************************************************************************/

const VOICE_KEY = "readAloudVoice";
const RATE_KEY = "readAloudRate";
const AUTOSCROLL_KEY = "readAloudAutoScroll";
const ASIDES_KEY = "readAloudAsides";
const AUTOCONTINUE_KEY = "readAloudAutoContinue";

// What happens to a knowl's body once its always-spoken title has been read.
// No "ask": the arrow keys already stop at every block.
const ASIDE_MODES = ["skip", "read"];

/**
 * Default "skip": a listener who has not touched the setting gets what a
 * reader who never clicks a knowl sees, which is also what the page looked
 * like before this feature existed.
 */
export function getSavedAsideMode() {
    const value = localStorage.getItem(ASIDES_KEY);
    return ASIDE_MODES.includes(value) ? value : "skip";
}

export function getSavedRate() {
    const value = Number(localStorage.getItem(RATE_KEY));
    return value >= 0.5 && value <= 2 ? value : 1;
}

export function getSavedAutoScroll() {
    return localStorage.getItem(AUTOSCROLL_KEY) !== "false";
}

/**
 * Whether finishing a page should carry the reading on to the next one.
 *
 * Default off, unlike auto-scroll: this one navigates.  A listener who walked
 * away from a page that has just gone quiet expects to still be on it, and a
 * reader who left the player open while doing something else would otherwise
 * find the browser several pages downstream.  Opt in, and it persists.
 */
export function getSavedAutoContinue() {
    return localStorage.getItem(AUTOCONTINUE_KEY) === "true";
}

export function documentLang() {
    return (document.documentElement.lang || "en").toLowerCase();
}

// Primary subtag of a language tag.  Engines are inconsistent about the
// separator — speech-dispatcher reports POSIX-style locales ("en_US") while
// the Web Speech spec uses BCP-47 ("en-US") — so normalize before comparing,
// or the language filter silently matches nothing.
function primaryLanguage(tag) {
    return (tag || "").toLowerCase().replace(/_/g, "-").split("-")[0];
}

/** Voices matching the document language, or all voices if none match. */
export function candidateVoices() {
    const all = window.speechSynthesis.getVoices();
    const lang = primaryLanguage(documentLang());
    const matching = all.filter((v) => primaryLanguage(v.lang) === lang);
    return matching.length ? matching : all;
}

// Voice quality varies enormously, and the voice a system reports as its
// default is often not the best one installed: on Linux, speech-dispatcher
// answers with espeak-ng even when a far better engine is present.  Rank by
// well-known engine names so a reader hears the best available voice without
// hunting through the picker.  Their own choice always wins and is
// remembered; this only decides where to start and how to order the list.
const VOICE_QUALITY_RULES = [
    { test: /neural|natural|premium|enhanced|siri/i, score: 3 },
    { test: /google|rhvoice|piper/i, score: 2 },
    { test: /espeak|flite|festival|dummy/i, score: -1 },
];

function voiceQuality(voice) {
    const name = `${voice.name} ${voice.voiceURI}`;
    const rule = VOICE_QUALITY_RULES.find((r) => r.test.test(name));
    return rule ? rule.score : 0;
}

/** Candidate voices, best first; ties keep the browser's own ordering. */
export function rankedVoices() {
    // Array.prototype.sort is stable, so equal-ranked voices stay in the
    // order the browser reported them.
    return candidateVoices()
        .slice()
        .sort(
            (a, b) =>
                voiceQuality(b) - voiceQuality(a) ||
                (b.default ? 1 : 0) - (a.default ? 1 : 0)
        );
}

// Memoized: on platforms that never enumerate voices this waits out its full
// deadline, and doing that on every play would put a pause before each one.
let voicesReady = null;

/**
 * Resolve once the engine has reported its voices — or once it is clear it
 * never will.
 *
 * getVoices() is empty until the voiceschanged event on Chrome, and
 * getSavedVoice() answers null for an empty list, which the engine reads as
 * "use the system default".  So asking too early does not fail loudly; it
 * quietly speaks in the wrong voice, ignoring both the reader's saved choice
 * and the quality ranking.  Only a start at page load is early enough to hit
 * this — auto-continue, in practice.
 *
 * The timeout is not a failure path: Firefox on Linux may enumerate nothing
 * while still speaking perfectly well through speech-dispatcher, and there
 * the system default is genuinely the right answer.
 */
export function whenVoicesReady(timeoutMs = 2500) {
    if (voicesReady) return voicesReady;
    voicesReady = new Promise((resolve) => {
        if (rankedVoices().length) {
            resolve();
            return;
        }
        let done = false;
        const finish = () => {
            if (done) return;
            done = true;
            clearInterval(poll);
            clearTimeout(timer);
            window.speechSynthesis.removeEventListener("voiceschanged", check);
            resolve();
        };
        const check = () => {
            if (rankedVoices().length) finish();
        };
        // Both, for the same reason the picker does: Chrome fires
        // voiceschanged exactly once, and this may be either side of it.
        window.speechSynthesis.addEventListener("voiceschanged", check);
        const poll = setInterval(check, 100);
        const timer = setTimeout(finish, timeoutMs);
    });
    return voicesReady;
}

/** The voice to use right now: saved choice if it still exists, else best. */
export function getSavedVoice() {
    const voices = rankedVoices();
    const saved = localStorage.getItem(VOICE_KEY);
    if (saved) {
        const match = voices.find((v) => v.voiceURI === saved);
        if (match) return match;
    }
    return voices[0] || null;
}

/**
 * Wire the readability-dialog controls (if present) and the player's rate
 * slider (if present).  `onChange` fires with {voice, rate, autoScroll}
 * whenever the user changes anything, so the queue can pick it up live.
 */
export function initSettingsControls(onChange) {
    const voiceSelect = document.getElementById("ptx-read-aloud-voice");
    const rateInput = document.getElementById("ptx-read-aloud-rate");
    const rateOutput = document.getElementById("ptx-read-aloud-rate-value");
    const autoScrollInput = document.getElementById("ptx-read-aloud-autoscroll");
    const autoContinueInput = document.getElementById("ptx-read-aloud-autocontinue");
    const asidesSelect = document.getElementById("ptx-read-aloud-asides");

    const notify = () => {
        onChange({
            voice: getSavedVoice(),
            rate: getSavedRate(),
            autoScroll: getSavedAutoScroll(),
            asideMode: getSavedAsideMode(),
        });
    };

    const voiceLabel = document.querySelector('label[for="ptx-read-aloud-voice"]');

    const populateVoices = () => {
        if (!voiceSelect) return;
        // Best-sounding first: the top of the list is what readers try.
        const voices = rankedVoices();

        // Some platforms report no voices at all while still speaking with a
        // system default — notably Firefox on Linux, where the browser may
        // not enumerate speech-dispatcher's list.  Offering an empty picker
        // looks broken, so hide the control until there is a real choice;
        // playback is unaffected, since an unset voice means "system
        // default" to every engine.
        const hidden = voices.length === 0;
        voiceSelect.hidden = hidden;
        if (voiceLabel) voiceLabel.hidden = hidden;
        if (hidden) return;

        const selected = getSavedVoice();
        voiceSelect.replaceChildren();
        for (const voice of voices) {
            const option = document.createElement("option");
            option.value = voice.voiceURI;
            option.textContent = `${voice.name} (${voice.lang})`;
            option.selected = selected && voice.voiceURI === selected.voiceURI;
            voiceSelect.appendChild(option);
        }
    };
    populateVoices();
    window.speechSynthesis.addEventListener("voiceschanged", populateVoices);

    // Chrome fills its voice list asynchronously but fires "voiceschanged"
    // only once — and these controls are built lazily, on the first click of
    // the read-aloud button, which can be either side of that event.  Miss it
    // and the picker stays empty for the whole session, so poll briefly as
    // well.  Stops as soon as voices appear.
    let attempts = 0;
    const poll = setInterval(() => {
        if (rankedVoices().length || ++attempts > 10) {
            clearInterval(poll);
            populateVoices();
        }
    }, 250);

    if (voiceSelect) {
        voiceSelect.addEventListener("change", () => {
            localStorage.setItem(VOICE_KEY, voiceSelect.value);
            notify();
        });
    }

    if (rateInput) {
        rateInput.value = getSavedRate();
        if (rateOutput) rateOutput.value = `${getSavedRate()}×`;
        rateInput.addEventListener("input", () => {
            const rate = Number(rateInput.value);
            if (rate >= 0.5 && rate <= 2) {
                localStorage.setItem(RATE_KEY, String(rate));
                if (rateOutput) rateOutput.value = `${rate}×`;
                notify();
            }
        });
    }

    if (asidesSelect) {
        asidesSelect.value = getSavedAsideMode();
        asidesSelect.addEventListener("change", () => {
            localStorage.setItem(ASIDES_KEY, asidesSelect.value);
            notify();
        });
    }

    if (autoScrollInput) {
        autoScrollInput.checked = getSavedAutoScroll();
        autoScrollInput.addEventListener("change", () => {
            localStorage.setItem(AUTOSCROLL_KEY, String(autoScrollInput.checked));
            notify();
        });
    }

    // No notify(): unlike the others this setting changes nothing about
    // playback in progress, and the player reads it once, at end of page.
    if (autoContinueInput) {
        autoContinueInput.checked = getSavedAutoContinue();
        autoContinueInput.addEventListener("change", () => {
            localStorage.setItem(
                AUTOCONTINUE_KEY,
                String(autoContinueInput.checked)
            );
        });
    }
}
