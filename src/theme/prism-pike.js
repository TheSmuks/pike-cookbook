/**
 * Inject Prism Pike grammar
 * This must be imported before using ```pike code blocks
 */

import Prism from 'prismjs';

// Prism.languages.pike grammar definition
(function(Prism) {
  Prism.languages.pike = {
    'comment': [
      {
        pattern: /\/\/.*/,
        greedy: true,
      },
      {
        pattern: /\/\*[\s\S]*?\*\//,
        greedy: true,
      },
      {
        // AutoDoc comments //!
        pattern: /\/\/![\s\S]*?$/,
        greedy: true,
        alias: 'doc-comment',
      },
    ],
    'string': {
      pattern: /(^|[^\\])"(?:[^"\\]|\\.)*"|(^|[^\\])'(?:[^'\\]|\\.)*'/,
      lookbehind: true,
      greedy: true,
    },
    'string-2': {
      // Multiline strings using #"
      pattern: /#"[^"]*"/,
      greedy: true,
    },
    'preprocessor': {
      pattern: /#\s*(?:pragma|require|if|else|elif|endif|define|undef|error|warning)\b/,
      greedy: true,
    },
    'keyword': /\b(?:if|else|elsif|for|foreach|while|do|switch|case|default|break|continue|return|class|enum|constant|import|inherit|virtual|static|final|public|protected|private|extern|nomask|inline|typedef|typeof|mapping|multiset|array|string|int|float|void|mixed|object|program|function|true|false)\b/,
    'type-keyword': /\b(?:string|int|float|bool|void|mixed|object|array|mapping|multiset|program|function)\b/,
    'function': /\b[a-zA-Z_]\w*(?=\s*\()/,
    'number': /\b(?:0x[\da-fA-F]+|\d+\.?\d*)(?:[eE][+-]?\d+)?\b/,
    'boolean': /\b(?:true|false)\b/,
    'operator': /->|=>|\+\+|--|[-+*/%&|^]=?|<<|>>|!=|==|<=|>=|&&|\|\||!|[<>]=?/,
    'punctuation': /[{}[\]();,.]|\\./,
    'constant': /\b[A-Z_][A-Z0-9_]*\b/,
    'builtin': /\b(?:Stdio|Process|Sql|Thread|Array|String|Mapping|Multiset|ADT|Protocols|Crypto|Math|Calendar|System|Globals|Loader|Master|Pike)\b/,
  };

  // AutoDoc tags as special keywords
  Prism.languages.insertBefore('pike', 'comment', {
    'autodoc-tag': {
      pattern: /@[a-zA-Z]+\b/,
      alias: 'keyword',
    },
  });
})(Prism);

export default Prism;
