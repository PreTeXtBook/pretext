(function() {
    if (!window.Prism) return;

    // Define grammar using safe string-based RegExp constructors
    var gdscript2Grammar = {
        'comment': new RegExp('#.*'),
        'string': {
            pattern: new RegExp('(?:r|f|b)?(?:"(?:\\\\.|[^"\\\\])*"|\'(?:\\\\.|[^\'\\\\])*\')', 'i'),
            greedy: true
        },
        'annotation': {
            pattern: new RegExp('@\\w+'),
            alias: 'builtin'
        },
        'keyword': new RegExp('\\b(?:as|assert|await|break|breakpoint|class|class_name|const|continue|enum|export|extends|for|func|if|elif|else|in|is|match|onready|pass|preload|return|self|setget|signal|static|super|tool|var|void|while|yield)\\b'),
        'function': new RegExp('\\b[a-z_]\\w*(?=\\s*\\()', 'i'),
        'number': new RegExp('\\b(?:0b+|0x[\\da-fA-F]+|\\d+(?:\\.\\d+)?(?:e[+-]?\\d+)?)\\b'),
        'boolean': new RegExp('\\b(?:true|false)\\b'),
        'operator': new RegExp('->|:=|&&|\\|\\||[-+*/%&|^!=<>]=?|~'),
        'punctuation': new RegExp('[{}[\\];(),.:]')
    };

    // Hook into Prism's token initialization pipeline
    Prism.hooks.add('before-tokenize', function(env) {
        if (env.language === 'gdscript') {
            Prism.languages.gdscript = gdscript2Grammar;
        }
    });

    // Pre-register it globally
    Prism.languages.gdscript = gdscript2Grammar;
})();
            