import React from 'react';
import { render } from '@testing-library/react';
import AutoDocHighlighter from '../AutoDocHighlighter';

describe('AutoDocHighlighter', () => {
  it('renders plain text without changes', () => {
    const { container } = render(<AutoDocHighlighter content="Hello world" />);
    expect(container.textContent).toBe('Hello world');
  });

  it('highlights @param tags', () => {
    const { container } = render(
      <AutoDocHighlighter content="@param x The x coordinate" />
    );
    expect(container.querySelector('.tag-param')).toBeInTheDocument();
    expect(container.textContent).toContain('x');
  });

  it('highlights @returns tags', () => {
    const { container } = render(
      <AutoDocHighlighter content="@returns The calculated value" />
    );
    expect(container.querySelector('.tag-returns')).toBeInTheDocument();
  });

  it('highlights @throws tags', () => {
    const { container } = render(
      <AutoDocHighlighter content="@throws Error if something fails" />
    );
    expect(container.querySelector('.tag-throws')).toBeInTheDocument();
  });

  it('highlights @seealso tags', () => {
    const { container } = render(
      <AutoDocHighlighter content="@seealso OtherFunction" />
    );
    expect(container.querySelector('.tag-seealso')).toBeInTheDocument();
  });

  it('highlights @example tags', () => {
    const { container } = render(
      <AutoDocHighlighter content="@example // code here" />
    );
    expect(container.querySelector('.tag-example')).toBeInTheDocument();
  });

  it('highlights @note tags', () => {
    const { container } = render(
      <AutoDocHighlighter content="@note Important information" />
    );
    expect(container.querySelector('.tag-note')).toBeInTheDocument();
  });

  it('highlights @deprecated tags', () => {
    const { container } = render(
      <AutoDocHighlighter content="@deprecated Use newFunction instead" />
    );
    expect(container.querySelector('.tag-deprecated')).toBeInTheDocument();
  });

  it('highlights @bugs tags', () => {
    const { container } = render(
      <AutoDocHighlighter content="@bugs May crash on large files" />
    );
    expect(container.querySelector('.tag-bugs')).toBeInTheDocument();
  });

  it('highlights @decl tags', () => {
    const { container } = render(
      <AutoDocHighlighter content="@decl int myFunction(int x)" />
    );
    expect(container.querySelector('.tag-decl')).toBeInTheDocument();
  });

  it('highlights @class tags', () => {
    const { container } = render(
      <AutoDocHighlighter content="@class MyClass" />
    );
    expect(container.querySelector('.tag-class')).toBeInTheDocument();
  });

  it('highlights @module tags', () => {
    const { container } = render(
      <AutoDocHighlighter content="@module MyModule" />
    );
    expect(container.querySelector('.tag-module')).toBeInTheDocument();
  });

  it('highlights inline italic markup @i{...@}', () => {
    const { container } = render(
      <AutoDocHighlighter content="This is @i{italic text@} here" />
    );
    expect(container.querySelector('.markup-i')).toBeInTheDocument();
    expect(container.textContent).toContain('italic text');
  });

  it('highlights inline bold markup @b{...@}', () => {
    const { container } = render(
      <AutoDocHighlighter content="This is @b{bold text@} here" />
    );
    expect(container.querySelector('.markup-b')).toBeInTheDocument();
    expect(container.textContent).toContain('bold text');
  });

  it('highlights inline teletype markup @tt{...@}', () => {
    const { container } = render(
      <AutoDocHighlighter content="Use @tt{code@} here" />
    );
    expect(container.querySelector('.markup-tt')).toBeInTheDocument();
    expect(container.textContent).toContain('code');
  });

  it('highlights inline reference markup @ref{...@}', () => {
    const { container } = render(
      <AutoDocHighlighter content="See @ref{function_name@} for details" />
    );
    expect(container.querySelector('.markup-ref')).toBeInTheDocument();
    expect(container.textContent).toContain('function_name');
  });

  it('highlights inline xml markup @xml{...@}', () => {
    const { container } = render(
      <AutoDocHighlighter content="Insert @xml{<br/>@} here" />
    );
    expect(container.querySelector('.markup-xml')).toBeInTheDocument();
  });

  it('handles multiple tags in one line', () => {
    const { container } = render(
      <AutoDocHighlighter content="@param x @param y @returns sum" />
    );
    expect(container.querySelector('.tag-param')).toBeInTheDocument();
    expect(container.querySelector('.tag-returns')).toBeInTheDocument();
  });

  it('handles mixed text and tags', () => {
    const { container } = render(
      <AutoDocHighlighter content="Calculate sum. @param x First number. @returns The result." />
    );
    expect(container.textContent).toContain('Calculate sum.');
    expect(container.querySelector('.tag-param')).toBeInTheDocument();
    expect(container.querySelector('.tag-returns')).toBeInTheDocument();
  });

  it('handles block keywords', () => {
    const { container } = render(
      <AutoDocHighlighter content="@dl @item Key @item Value @enddl" />
    );
    expect(container.querySelector('.tag-dl')).toBeInTheDocument();
    expect(container.querySelector('.tag-item')).toBeInTheDocument();
    expect(container.querySelector('.tag-enddl')).toBeInTheDocument();
  });
});
