
if (allTraceData === undefined) {
    var allTraceData = {};
}
(function() { // IIFE to avoid variable collision
    let codelensID = "rs-regression-codelens";  //fallback
    let partnerCodelens = document.currentScript.parentElement.querySelector(".pytutorVisualizer");
    if (partnerCodelens) {
        codelensID = partnerCodelens.id;
    }
    allTraceData[codelensID] = {"code": "a = 5\nb = a + 2\nc = a * b\n", "trace": [{"line": 1, "event": "step_line", "func_name": "<module>", "globals": {}, "ordered_globals": [], "stack_to_render": [], "heap": {}, "stdout": ""}, {"line": 2, "event": "step_line", "func_name": "<module>", "globals": {"a": 5}, "ordered_globals": ["a"], "stack_to_render": [], "heap": {}, "stdout": ""}, {"line": 3, "event": "step_line", "func_name": "<module>", "globals": {"a": 5, "b": 7}, "ordered_globals": ["a", "b"], "stack_to_render": [], "heap": {}, "stdout": "", "question": {"text": "What value is assigned to <code class=\"code-inline tex2jax_ignore\">c</code>?", "correctText": "35", "feedback": "Multiply the current values of <code class=\"code-inline tex2jax_ignore\">a</code> and <code class=\"code-inline tex2jax_ignore\">b</code>."}}, {"line": 3, "event": "return", "func_name": "<module>", "globals": {"a": 5, "b": 7, "c": 35}, "ordered_globals": ["a", "b", "c"], "stack_to_render": [], "heap": {}, "stdout": ""}], "startingInstruction": 1};
})();