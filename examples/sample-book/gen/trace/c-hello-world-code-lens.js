
if (allTraceData === undefined) {
    var allTraceData = {};
}
(function() { // IIFE to avoid variable collision
    let codelensID = "rs-c-hello-world-code-lens";  //fallback
    let partnerCodelens = document.currentScript.parentElement.querySelector(".pytutorVisualizer");
    if (partnerCodelens) {
        codelensID = partnerCodelens.id;
    }
    allTraceData[codelensID] = {"code": "#include <stdio.h>\n\nint main(void)\n{\n    puts(\"Hello, World!\");\n}\n", "trace": [{"event": "step_line", "func_name": "main", "globals": {}, "heap": {}, "line": 5, "ordered_globals": [], "stack_to_render": [{"encoded_locals": {}, "frame_id": "0xFFF000BE0", "func_name": "main", "is_highlighted": true, "is_parent": false, "is_zombie": false, "line": 4, "ordered_varnames": [], "parent_frame_id_list": [], "unique_hash": "main_0xFFF000BE0"}], "stdout": ""}, {"event": "return", "func_name": "main", "globals": {}, "heap": {}, "line": 6, "ordered_globals": [], "stack_to_render": [{"encoded_locals": {}, "frame_id": "0xFFF000BE0", "func_name": "main", "is_highlighted": true, "is_parent": false, "is_zombie": false, "line": 6, "ordered_varnames": [], "parent_frame_id_list": [], "unique_hash": "main_0xFFF000BE0"}], "stdout": "Hello, World!\n"}], "startingInstruction": 0};
})();