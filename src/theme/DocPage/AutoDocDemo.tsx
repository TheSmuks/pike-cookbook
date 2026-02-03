import React from 'react';
import Layout from '@theme/Layout';
import AutoDocHighlighter from '@site/src/components/AutoDocHighlighter';

export default function AutoDocDemo(): React.ReactElement {
  const examples = [
    {
      title: 'Function Documentation',
      code: `//! Calculate the factorial of a number.
//! @param n
//!   Non-negative integer to calculate factorial for
//! @returns
//!   Factorial of n
//! @throws
//!   Error if n is negative
int factorial(int n)`,
    },
    {
      title: 'Multiple Parameters',
      code: `//! Connect to a database.
//! @param host
//!   Database host address
//! @param port
//!   Database port number
//! @param username
//!   Database username
//! @returns
//!   Database connection object
//! @throws
//!   ConnectionError if connection fails`,
    },
    {
      title: 'Class Documentation',
      code: `//! A logger class with different severity levels.
//! @note
//!   Log messages are written to stderr by default
//! @seealso
//!   @[FileLogger] for file-based logging
//! @deprecated
//!   Use @[AdvancedLogger] instead
//! @bugs
//!   May lose messages under high load`,
    },
    {
      title: 'Inline Markup',
      code: `//! This is @i{italic@} and @b{bold@} text.
//! See @ref{function_name@} for more info.
//! Use @tt{code@} for monospace.
//! Insert @xml{<br/>@} for line breaks.`,
    },
    {
      title: 'Module Documentation',
      code: `//! @module Image
//! Image processing utilities for Pike.
//! @example
//! // Load and resize an image
//! Stdio.Image img = Image.load("input.jpg");
//! @note
//!   Image formats support varies by system
//! @bugs
//!   Some transparency modes not supported in JPEG
//! @seealso
//!   @[Image.load()], @[Image.save()]`,
    },
  ];

  return (
    <Layout title="AutoDoc Demo" description="AutoDoc syntax highlighting demo">
      <main className="container margin-vert--xl">
        <h1>AutoDoc Syntax Highlighting Demo</h1>
        <p>
          This page demonstrates the AutoDoc syntax highlighting component. The
          component automatically detects and highlights AutoDoc tags and inline
          markup.
        </p>

        {examples.map((example, index) => (
          <div key={index} className="margin-bottom--xl">
            <h2>{example.title}</h2>
            <div
              style={{
                backgroundColor: '#f6f8fa',
                border: '1px solid #d0d7de',
                borderRadius: '6px',
                padding: '16px',
                fontFamily: 'monospace',
                whiteSpace: 'pre-wrap',
                fontSize: '14px',
                lineHeight: '1.5',
              }}
            >
              <AutoDocHighlighter content={example.code} />
            </div>
          </div>
        ))}

        <h2>Supported Tags</h2>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: '16px' }}>
          <div>
            <h3>Meta Keywords</h3>
            <ul>
              <li>
                <AutoDocHighlighter content="@decl" />
              </li>
              <li>
                <AutoDocHighlighter content="@class" />
              </li>
              <li>
                <AutoDocHighlighter content="@endclass" />
              </li>
              <li>
                <AutoDocHighlighter content="@module" />
              </li>
              <li>
                <AutoDocHighlighter content="@endmodule" />
              </li>
            </ul>
          </div>

          <div>
            <h3>Common Tags</h3>
            <ul>
              <li>
                <AutoDocHighlighter content="@param" />
              </li>
              <li>
                <AutoDocHighlighter content="@returns" />
              </li>
              <li>
                <AutoDocHighlighter content="@throws" />
              </li>
              <li>
                <AutoDocHighlighter content="@seealso" />
              </li>
              <li>
                <AutoDocHighlighter content="@example" />
              </li>
              <li>
                <AutoDocHighlighter content="@note" />
              </li>
              <li>
                <AutoDocHighlighter content="@deprecated" />
              </li>
              <li>
                <AutoDocHighlighter content="@bugs" />
              </li>
            </ul>
          </div>

          <div>
            <h3>Inline Markup</h3>
            <ul>
              <li>
                <AutoDocHighlighter content="@i{italic text@}" />
              </li>
              <li>
                <AutoDocHighlighter content="@b{bold text@}" />
              </li>
              <li>
                <AutoDocHighlighter content="@tt{monospace@}" />
              </li>
              <li>
                <AutoDocHighlighter content="@ref{reference@}" />
              </li>
              <li>
                <AutoDocHighlighter content="@xml{<tag/>@}" />
              </li>
            </ul>
          </div>

          <div>
            <h3>Block Keywords</h3>
            <ul>
              <li>
                <AutoDocHighlighter content="@dl" />
              </li>
              <li>
                <AutoDocHighlighter content="@enddl" />
              </li>
              <li>
                <AutoDocHighlighter content="@mapping" />
              </li>
              <li>
                <AutoDocHighlighter content="@endmapping" />
              </li>
              <li>
                <AutoDocHighlighter content="@array" />
              </li>
              <li>
                <AutoDocHighlighter content="@endarray" />
              </li>
              <li>
                <AutoDocHighlighter content="@item" />
              </li>
              <li>
                <AutoDocHighlighter content="@member" />
              </li>
            </ul>
          </div>
        </div>
      </main>
    </Layout>
  );
}
