// Node style of import
import { BTM } from 'btm-expressions/src/BTM_root.js';
import { RNG } from 'btm-expressions/src/random.js';
import { readFileSync, writeFileSync } from 'node:fs';
import { parseArgs} from 'node:util';

// Deno style of import
// import { readFileSync,writeFileSync } from "node:fs";
// import { BTM } from "npm:btm-expressions/src/BTM_root.js";
// import { RNG } from "npm:btm-expressions/src/random.js";
// import { parseArgs } from "jsr:@std/cli/parse-args";

// Node parse arguments
const {
  values: { input, output },
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
  },
});
const args = { input: input, output: output };

// Deno parse arguments
// const args = parseArgs(Deno.args, {
//     string: ["input", "output"]
// });

const evaluate = function(setup, seed, substitutions) {
    var my_rng = new RNG({seed: seed});
    var execFcnStr = "var v = {};\n" + setup + "return v;\n";
    const execFcn = new Function('BTM', 'rand', 'subs', execFcnStr);
    return execFcn(BTM, my_rng.rand, substitutions);
}

try {
    const data = readFileSync(args.input, 'utf8');
    const dynamic_problems = JSON.parse(data);
    var xmlResponse = "<xml>";
    for (var i in dynamic_problems) {
        var prob = dynamic_problems[i];
        if (prob.exercise_id) {
            var substitutions = {};
            for (var j in prob.exercise_evals) {
                var obj = prob.exercise_evals[j];
                substitutions[obj] = "";
            }
            xmlResponse += "<dynamic-substitution id=\"" + prob.exercise_id + "\">";
            var dyn_vars = evaluate(prob.exercise_setup, prob.exercise_seed, substitutions);
            var subs_keys = Object.keys(substitutions);
            // To compare old version to this version with diff, we need to create
            // a substitution element for each occurrence in the problem.
            // Remove this line to remove repeated elements.
            subs_keys = prob.exercise_evals;  // <-- This line!
            for (var k in subs_keys) {
                var key = subs_keys[k];
                var obj = dyn_vars[key];
                var obj_str;
                if (obj.toTeX) {
                    obj_str = obj.toTeX();
                } else {
                    obj_str = obj.toString();
                }
                xmlResponse += "<eval-subst obj=\"" + key + "\">" + obj_str + "</eval-subst>";
            }
            xmlResponse += "</dynamic-substitution>";
        }
    }
    xmlResponse += "</xml>";
    writeFileSync(args.output, xmlResponse, 'utf8');
} catch (err) {
    console.error("Error creating dynamic substitutions:", err);
} 
