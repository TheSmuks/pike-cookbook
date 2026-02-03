import Prism from 'prismjs';

// Pike language definition
if (typeof Prism !== 'undefined') {
  Prism.languages.pike = {
    'comment': [
      { pattern: /\/\/.*|\/\*[\s\S]*?\*\//, greedy: true },
      { pattern: /#.*$/, greedy: true }
    ],
    'string': {
      pattern: /(["'])((?:(?!\1)[^\\]|\\.)*|\1)/,
      greedy: true,
      inside: {
        'interpolation': {
          pattern: /(?:\$\{[^}]+\}|\$\w+)/,
          inside: {
            'expression': {
              pattern: /\{[^}]+\}/,
              inside: null // see below
            },
            'variable': /\$\w+/
          }
        }
      }
    },
    'keyword': /\b(?:break|case|catch|class|continue|default|do|else|float|for|foreach|function|gauge|if|import|int|lambda|list|mapping|mixed|module|multiset|namespace|nomask|object|private|protected|public|return|sscanf|string|switch|this|throw|try|varargs|void|while|__attribute__|__deprecated__|__deprecated__\(\)|__hide__|__no_deprecation_warning__|__null__|__pie__|__post__|__pre__|__Deprecated__|__Hide__|__NoDeprecationWarning__|__null__|__pie__|__post__|__pre__)\b/,
    'function': /\b\w+(?=\s*\()/,
    'number': /\b(?:0[xX][\da-fA-F]+|\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?\b/,
    'boolean': /\b(?:true|false|yes|no)\b/,
    'operator': /[-+*/%&|^!=<>]=?|&&|\|\||<<|>>|~|\+\+|--|\.\.\.|::|\b(?:and|or|not|xor|eq|ne|lt|le|gt|ge)\b/,
    'punctuation': /[{}[\];:(),.]/,
    'variable': /\$\w+/,
    'class-name': /\b[A-Z]\w*\b/
  };

  // Support nested interpolation expressions
  if (Prism.languages.pike.string.inside?.interpolation?.inside?.expression) {
    Prism.languages.pike.string.inside.interpolation.inside.expression.inside = Prism.languages.pike;
  }
}

export default Prism.languages.pike;
