/**
 * Prism.js Pike Language Definition
 * Adds syntax highlighting support for the Pike programming language
 */

// Pike language grammar for Prism.js
Prism.languages.pike = {
  'comment': [
    {
      pattern: /(^|[^\\])\/\*[\s\S]*?\*\//,
      lookbehind: true
    },
    {
      pattern: /(^|[^\\:])\/\/.*/,
      lookbehind: true,
      greedy: true
    }
  ],
  'string': {
    pattern: /(["'])(?:(?!\1)[^\\]|\\[\s\S])*\1/,
    greedy: true
  },
  'keyword': /\b(?:array|break|case|catch|class|constant|continue|default|do|else|enum|float|for|foreach|function|if|import|inherit|inline|int|lambda|mapping|mixed|multiset|object|predef|private|protected|public|return|static|string|switch|this|typeof|void|while)\b/,
  'class-name': {
    pattern: /\b[A-Z][a-zA-Z0-9_]*\b/,
    lookbehind: true
  },
  'number': /\b0x[\da-f]+\b|(?:\b\d+\.?\d*|\B\.\d+)(?:e[+-]?\d+)?\b/i,
  'operator': /=>|->|\+\+|--|&&|\|\||::|<<|>>|[-+~!%^&*=<>=|\/?:.]/,
  'punctuation': /[{}[\]();,.]/
};

// Export for Docusaurus
module.exports = Prism;
