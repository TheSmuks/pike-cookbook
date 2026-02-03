import siteConfig from '@generated/docusaurus.config';

export default function prismIncludeLanguages(PrismObject) {
  const {
    themeConfig: {prism},
  } = siteConfig;
  const {additionalLanguages} = prism;

  // Load additional languages from config
  // Skip 'pike' as it's registered below
  globalThis.Prism = PrismObject;
  additionalLanguages.forEach((lang) => {
    if (lang !== 'pike') {
      require(`prismjs/components/prism-${lang}`);
    }
  });
  delete globalThis.Prism;

  // Register Pike language with comprehensive syntax highlighting
  PrismObject.languages.pike = {
    // Comments: //, /* */, and #! shebang
    // AutoDoc comments (//!) are handled separately to enable tag highlighting
    'comment': [
      {
        pattern: /\/\/![^\n]*/,
        greedy: true,
        inside: {
          'autodoc-inline': {
            pattern: /@(?:i|b|tt|ref|xml)\{[^@]*@/
          },
          'autodoc-tag': {
            pattern: /@(?:param|return|returns|throws|throw|seealso|example|note|deprecated|bugs|decl|class|endclass|module|endmodule|type|member|item|index|dl|enddl|mapping|endmapping|array|endarray|namespace|endnamespace|enum|endenum|constant|variable|inherit|typedef|directive|fixme|todo|ol|endol|ul|endul|li|table|endtable|row|col|image|url|expr|code)\b/
          }
        }
      },
      {
        pattern: /\/\*[\s\S]*?\*\//,
        greedy: true
      },
      {
        // Generic // comments EXCLUDING //! (which must come first)
        pattern: /\/\/(?!\!).*$/,
        greedy: true
      },
      {
        pattern: /^#!.*/,
        greedy: true
      }
    ],

    // Preprocessor directives
    'preprocessor': {
      pattern: /#\s*(?:include|if|ifdef|ifndef|else|elif|endif|define|undef|pragma|pike|charset|string|require)\b.*/,
      greedy: true,
      alias: 'property'
    },

    // Strings with interpolation support
    'string': {
      pattern: /(["'])(?:(?!\1)[^\\]|\\.)*\1/,
      greedy: true,
      inside: {
        'interpolation': {
          pattern: /%(?:\d+\$)?[-+#0 ]*(?:\d+|\*)?(?:\.(?:\d+|\*))?[diouxXeEfFgGaAcspn%]/,
          alias: 'variable'
        }
      }
    },

    // Multiline strings
    'string-multiline': {
      pattern: /#"(?:[^"\\]|\\.)*"/,
      greedy: true,
      alias: 'string'
    },

    // Type keywords - these are types, should be distinct
    'type-keyword': {
      pattern: /\b(?:int|float|string|array|mapping|multiset|mixed|object|program|function|void)\b/,
      alias: 'keyword'
    },

    // Control flow keywords
    'keyword': /\b(?:break|case|catch|class|constant|continue|default|do|else|enum|final|for|foreach|gauge|global|if|import|inherit|inline|lambda|local|nomask|optional|predef|private|protected|public|return|sscanf|static|switch|this|this_program|throw|try|typedef|typeof|variant|while)\b/,

    // Boolean and special values
    'boolean': /\b(?:true|false|UNDEFINED)\b/,

    // Built-in functions - common Pike functions
    'builtin': /\b(?:write|werror|sprintf|sscanf|sizeof|indices|values|sort|reverse|map|filter|replace|search|has_index|has_value|zero_type|stringp|intp|floatp|arrayp|mappingp|multisetp|objectp|programp|functionp|callablep|allocate|aggregate|aggregate_mapping|aggregate_multiset|copy_value|destruct|equal|hash|hash_value|m_delete|mkmapping|mkmultiset|rows|column|predef|master|this_object|object_program|compile|compile_string|compile_file|add_constant|all_constants|random|random_seed|time|localtime|gmtime|mktime|ctime|sleep|getenv|putenv|cd|getcwd|file_stat|get_dir|mkdir|rm|mv|Stdio|Process|String|Array|Mapping|Int|Float|Program|Object|Function|Thread|Calendar|Protocols|Standards|System|Regexp)\b/,

    // Class names (PascalCase identifiers)
    'class-name': {
      pattern: /\b[A-Z][A-Za-z0-9_]*\b/,
      lookbehind: false
    },

    // Function calls
    'function': {
      pattern: /\b[a-z_][a-z0-9_]*(?=\s*\()/i,
    },

    // Numbers - hex, octal, binary, float, int
    'number': [
      // Hexadecimal
      { pattern: /\b0[xX][\da-fA-F]+\b/ },
      // Octal
      { pattern: /\b0[oO][0-7]+\b/ },
      // Binary
      { pattern: /\b0[bB][01]+\b/ },
      // Float with exponent
      { pattern: /\b\d+\.\d+(?:[eE][+-]?\d+)?\b/ },
      // Integer with optional exponent
      { pattern: /\b\d+(?:[eE][+-]?\d+)?\b/ }
    ],

    // Operators
    'operator': [
      // Arrow and scope operators
      { pattern: /->|::/ },
      // Compound assignment
      { pattern: /[+\-*/%&|^]=|<<=|>>=/ },
      // Comparison
      { pattern: /[!=<>]=?|<=>/ },
      // Logical
      { pattern: /&&|\|\|/ },
      // Bitwise shifts
      { pattern: /<<|>>/ },
      // Increment/decrement
      { pattern: /\+\+|--/ },
      // Range
      { pattern: /\.\.\.?/ },
      // Other operators
      { pattern: /[+\-*/%&|^~!]/ }
    ],

    // Punctuation
    'punctuation': /[{}[\]();,.:@]/,

    // Backtick operator calls
    'backtick-operator': {
      pattern: /`[+\-*/%&|^~!=<>]+/,
      alias: 'function'
    },

    // Variable (identifiers that aren't caught by other rules)
    'variable': /\b[a-z_][a-z0-9_]*\b/i
  };
}
