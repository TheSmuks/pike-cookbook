// Import Prism and register Pike language
import Prism from 'prismjs';

// Import and execute Pike language definition
import pikeLanguageDef from './js/prism/prism-pike.js';

// Register Pike language with Prism
if (Prism && !Prism.languages.pike) {
  Prism.languages.pike = pikeLanguageDef;
}

// Ensure it's available globally for Docusaurus
if (typeof window !== 'undefined') {
  if (!window.Prism) {
    window.Prism = Prism;
  }
}
