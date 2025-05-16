
if (allTraceData === undefined) {
    var allTraceData = {};
}
(function() { // IIFE to avoid variable collision
    let codelensID = "rs-java-hello-world-code-lens";  //fallback
    let partnerCodelens = document.currentScript.parentElement.querySelector(".pytutorVisualizer");
    if (partnerCodelens) {
        codelensID = partnerCodelens.id;
    }
    allTraceData[codelensID] = {"code": "public class HelloWorld {\n    public static void main(String[] args) {\n        System.out.println(\"Hello, World!\");\n    }\n}\n", "stdin": "", "trace": [{"stdout": "", "event": "call", "line": 3, "stack_to_render": [{"func_name": "main:3", "encoded_locals": {}, "ordered_varnames": [], "parent_frame_id_list": [], "is_highlighted": true, "is_zombie": false, "is_parent": false, "unique_hash": "1", "frame_id": 1}], "globals": {}, "ordered_globals": [], "func_name": "main", "heap": {}}, {"stdout": "", "event": "step_line", "line": 3, "stack_to_render": [{"func_name": "main:3", "encoded_locals": {}, "ordered_varnames": [], "parent_frame_id_list": [], "is_highlighted": true, "is_zombie": false, "is_parent": false, "unique_hash": "2", "frame_id": 2}], "globals": {}, "ordered_globals": [], "func_name": "main", "heap": {}}, {"stdout": "Hello, World!\n", "event": "step_line", "line": 4, "stack_to_render": [{"func_name": "main:4", "encoded_locals": {}, "ordered_varnames": [], "parent_frame_id_list": [], "is_highlighted": true, "is_zombie": false, "is_parent": false, "unique_hash": "5", "frame_id": 5}], "globals": {}, "ordered_globals": [], "func_name": "main", "heap": {}}, {"stdout": "Hello, World!\n", "event": "return", "line": 4, "stack_to_render": [{"func_name": "main:4", "encoded_locals": {"__return__": ["VOID"]}, "ordered_varnames": ["__return__"], "parent_frame_id_list": [], "is_highlighted": true, "is_zombie": false, "is_parent": false, "unique_hash": "6", "frame_id": 6}], "globals": {}, "ordered_globals": [], "func_name": "main", "heap": {}}], "userlog": "Debugger VM maxMemory: 444M\n", "startingInstruction": 0};
})();