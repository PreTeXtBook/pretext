/*******************************************************************************
 * speech-queue.js — state machine driving window.speechSynthesis
 *******************************************************************************
 * States: idle → speaking(i) → paused(i) → ended, where i indexes the
 * utterance plan produced by segmenter.js.  One SpeechSynthesisUtterance per
 * plan entry; onend advances to the next.  Callbacks let the UI layer drive
 * the highlighter, auto-scroll, and MediaSession without this file touching
 * any of them.
 *
 * Platform quirks handled here (see the design doc's quirk table):
 *   - onend also fires after cancel(): a generation counter distinguishes a
 *     natural end from our own cancellation.
 *   - pause() is unreliable on Android Chrome: there, pause is implemented as
 *     cancel + remember-the-index, and resume re-speaks the current sentence.
 *     Sentence-sized utterances make that restart unnoticeable.
 *
 * The plan holds *every* block on the page, including the bodies of asides the
 * listener has not opened.  The listening mode is applied here, while
 * advancing, rather than at collection time — which is why the mode can change
 * mid-page with no recollection, and why the navigation keys can reach content
 * that is not currently being read.
 ******************************************************************************/

import {
    nextBlockStart,
    nextSpeakable,
    previousBlockStart,
    shouldSpeak,
    skipTarget,
} from "./navigation.js";

export class SpeechQueue {
    /**
     * opts:
     *   synth        the SpeechSynthesis instance (injectable for testing)
     *   onUtterance  (index, planItem) fired as each utterance starts
     *   onState      (state) fired on every state change
     *   onEnded      () fired when the plan runs out naturally
     */
    constructor(opts = {}) {
        this.synth = opts.synth || window.speechSynthesis;
        this.onUtterance = opts.onUtterance || (() => {});
        this.onState = opts.onState || (() => {});
        this.onEnded = opts.onEnded || (() => {});

        // Names the kind of block the arrow keys have landed on ("Theorem",
        // "Paragraph"); the UI layer supplies it, since it reads the DOM.
        this.describeBlock = opts.describeBlock || (() => null);

        this.plan = [];
        this.blocks = [];
        // "read" | "skip" — what happens to an aside's body once its
        // always-spoken title has been read.  There is no "pause and ask"
        // mode: the arrow keys already stop at every block, so asking would
        // be a second way to do the same thing.
        this.mode = opts.mode || "skip";
        // Asides the listener explicitly descended into, which override the
        // mode for that aside alone.
        this.entered = new Set();
        // Parked at a block head after an arrow jump, awaiting play/right.
        this.pendingStart = false;
        this.index = 0;
        this.state = "idle";
        this.voice = null;
        this.rate = 1;
        this.lang = null;

        // Incremented on every cancel so stale onend events are ignored.
        this.generation = 0;

        // Native pause is broken on Android Chrome; use cancel+restart there.
        this.nativePause = !/Android/i.test(navigator.userAgent);
    }

    setPlan(plan, blocks) {
        this.stop();
        this.plan = plan;
        this.blocks = blocks || [];
        this.entered = new Set();
        // Parked at a block head after an arrow jump, awaiting play/right.
        this.pendingStart = false;
        this.index = 0;
    }

    /** Change listening mode live; takes effect at the next block boundary. */
    setMode(mode) {
        this.mode = mode;
    }

    setVoice(voice) {
        this.voice = voice;
        this._restartIfSpeaking();
    }

    setRate(rate) {
        this.rate = rate;
        this._restartIfSpeaking();
    }

    setLang(lang) {
        this.lang = lang;
    }

    _setState(state) {
        if (this.state !== state) {
            this.state = state;
            this.onState(state);
        }
    }

    _restartIfSpeaking() {
        // Voice/rate cannot change mid-utterance; restart the current
        // sentence so the change is heard immediately.
        if (this.state === "speaking") {
            this.playFrom(this.index);
        }
    }

    playFrom(index) {
        if (!this.plan.length) return;
        this.generation++;
        this.synth.cancel();
        this.index = Math.max(0, Math.min(index, this.plan.length - 1));
        this._setState("speaking");
        this._speakCurrent();
    }

    _speakCurrent() {
        const item = this.plan[this.index];
        const generation = this.generation;
        const utterance = new SpeechSynthesisUtterance(item.text);
        if (this.voice) utterance.voice = this.voice;
        if (this.lang) utterance.lang = this.lang;
        utterance.rate = this.rate;

        utterance.onstart = () => {
            if (generation !== this.generation) return;
            this.onUtterance(this.index, item);
        };
        const advance = () => {
            if (generation !== this.generation) return;
            const next = this._nextIndex();
            if (next >= 0) {
                this.index = next;
                this._speakCurrent();
            } else {
                this._setState("ended");
                this.onEnded();
            }
        };
        utterance.onend = advance;
        // A voice/synthesis error on one sentence should not kill the whole
        // reading session; skip to the next utterance.
        utterance.onerror = (e) => {
            if (e.error === "canceled" || e.error === "interrupted") return;
            // "not-allowed" is different in kind: the engine refused to speak
            // at all, because nothing on this page has been clicked yet.  It
            // will refuse every following sentence too, so advancing would
            // race silently through the entire page and then report a
            // natural end — which the auto-continue setting would act on.
            // Fall back to idle: pressing play is itself the user gesture
            // the engine was waiting for, and nothing was heard, so starting
            // the page over is what the listener expects.
            if (e.error === "not-allowed") {
                this._setState("idle");
                return;
            }
            advance();
        };
        this.synth.speak(utterance);
    }

    /**
     * Speak one string outside the plan, then call `done` — exactly once.
     *
     * For announcements that must be heard before something irreversible
     * happens to this queue, currently only the auto-continue warning ahead
     * of navigating away.  Neither onend nor onerror is guaranteed to arrive
     * (an engine with no voices may drop the utterance in silence), so a
     * timer backstops them: `done` is a navigation, and never firing it
     * would strand the listener on a page that has stopped reading.
     */
    speakOnce(text, done) {
        let finished = false;
        const finish = () => {
            if (finished) return;
            finished = true;
            clearTimeout(timer);
            done();
        };
        const timer = setTimeout(finish, 6000);
        try {
            const utterance = new SpeechSynthesisUtterance(text);
            if (this.voice) utterance.voice = this.voice;
            if (this.lang) utterance.lang = this.lang;
            utterance.rate = this.rate;
            utterance.onend = finish;
            utterance.onerror = finish;
            this.synth.speak(utterance);
        } catch (e) {
            finish();
        }
    }

    pause() {
        if (this.state !== "speaking") return;
        if (this.nativePause) {
            this.synth.pause();
        } else {
            this.generation++;
            this.synth.cancel();
        }
        this._setState("paused");
    }

    resume() {
        if (this.state !== "paused") return;
        // Parked at the head of a block after an arrow-key jump: nothing is
        // queued in the engine, so resuming means starting that block.
        if (this.pendingStart) {
            this.pendingStart = false;
            // Accepting a knowl's title opens the knowl.  This is the only
            // way into hidden content while in skip mode, and it mirrors what
            // the title means on screen: clicking it reveals the body.
            this.enterAsideHere();
            this.playFrom(this.index);
            return;
        }
        if (this.nativePause) {
            this.synth.resume();
            this._setState("speaking");
        } else {
            this.playFrom(this.index);
        }
    }

    toggle() {
        if (this.state === "speaking") {
            this.pause();
        } else if (this.state === "paused") {
            this.resume();
        } else {
            this.playFrom(this.index);
        }
    }

    stop() {
        this.generation++;
        this.synth.cancel();
        this._setState("idle");
    }

    next() {
        const next = this._nextIndex();
        if (next >= 0) this.playFrom(next);
    }

    prev() {
        const prev = this._prevIndex();
        if (prev >= 0) this.playFrom(prev);
    }

    /** First plan index at or after the given block, for click-to-start. */
    indexForBlock(blockIndex) {
        for (let i = 0; i < this.plan.length; i++) {
            if (this.plan[i].blockIndex >= blockIndex) return i;
        }
        return -1;
    }

    /** Block index behind a plan index, or -1. */
    _blockIndex(planIndex = this.index) {
        const item = this.plan[planIndex];
        return item ? item.blockIndex : -1;
    }

    /**
     * The next plan index to speak, honouring the listening mode, or -1 at
     * the end of the page.  With no block data (console use, tests) this is
     * plain linear advance.
     */
    _nextIndex() {
        const candidate = this.index + 1;
        if (candidate >= this.plan.length) return -1;
        if (!this.blocks.length) return candidate;

        const blockIndex = this._blockIndex(candidate);
        if (shouldSpeak(this.blocks, blockIndex, this.mode, this.entered)) {
            return candidate;
        }
        const target = nextSpeakable(
            this.blocks,
            blockIndex,
            this.mode,
            this.entered
        );
        if (target < 0) return -1;
        const planIndex = this.indexForBlock(target);
        // Never move backwards, however odd the block data: that would loop.
        return planIndex > this.index ? planIndex : -1;
    }

    /**
     * The previous plan index to speak, or -1 at the top of the page.
     *
     * Stepping back has to honour the mode just as advancing does, or the
     * sentence after a skipped knowl steps *into* content the listener never
     * heard — going backwards through a theorem they were never read.
     */
    _prevIndex() {
        if (!this.blocks.length) return this.index > 0 ? this.index - 1 : -1;
        for (let i = this.index - 1; i >= 0; i--) {
            if (this._allowed(this.plan[i].blockIndex)) return i;
        }
        return -1;
    }

    /** Jump to a block, reporting whether there was anywhere to go. */
    _goToBlock(blockIndex) {
        if (blockIndex < 0) return false;
        const planIndex = this.indexForBlock(blockIndex);
        if (planIndex < 0) return false;
        this.playFrom(planIndex);
        return true;
    }

    /**
     * Move to the head of the previous block, or of the current one when the
     * listener is part-way through it, then announce and wait.
     */
    previousBlock() {
        return this._jumpAnnouncing(
            previousBlockStart(this.plan, this.index, (b) => this._allowed(b))
        );
    }

    /** Move to the head of the next block, then announce and wait. */
    nextBlock() {
        return this._jumpAnnouncing(
            nextBlockStart(this.plan, this.index, (b) => this._allowed(b))
        );
    }

    /**
     * If the current block is the title of an aside that is not being read,
     * mark it opened so the mode filter lets its body through.  Returns the
     * aside, or null when there was nothing to open.
     */
    enterAsideHere() {
        const block = this.blocks[this._blockIndex()];
        if (!block || !block.summary) return null;
        const asides = block.path.filter((n) => n.aside);
        const own = asides[asides.length - 1];
        if (!own || this.entered.has(own.el)) return null;
        this.entered.add(own.el);
        return own;
    }

    _allowed(blockIndex) {
        if (!this.blocks.length) return true;
        return shouldSpeak(this.blocks, blockIndex, this.mode, this.entered);
    }

    /**
     * Park at a block: say what kind of block it is, then stop and wait for
     * the listener rather than reading on.  Arrow keys are for surveying the
     * page, so landing somewhere must not commit to reading it.
     */
    _jumpAnnouncing(planIndex) {
        if (planIndex < 0) return false;
        this.generation++;
        this.synth.cancel();
        this.index = planIndex;
        this.pendingStart = true;

        const item = this.plan[planIndex];
        this.onUtterance(planIndex, item);

        const text = this.describeBlock(item.blockIndex);
        this._setState("paused");
        if (text) this._speakOnce(text);
        return true;
    }

    /** Speak one throwaway line that is not part of the plan. */
    _speakOnce(text) {
        const utterance = new SpeechSynthesisUtterance(text);
        if (this.voice) utterance.voice = this.voice;
        if (this.lang) utterance.lang = this.lang;
        utterance.rate = this.rate;
        this.synth.speak(utterance);
    }

    /** Skip the innermost theorem/example/proof and resume after it. */
    skipBlock() {
        return this._goToBlock(skipTarget(this.blocks, this._blockIndex()));
    }
}
