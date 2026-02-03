#!/usr/bin/env python3

import re
import html
from pathlib import Path

def clean_text(text):
    """Clean and decode HTML entities"""
    text = html.unescape(text)
    text = re.sub(r'\s+', ' ', text)  # Normalize whitespace
    text = text.strip()
    return text

def extract_section_content(content):
    """Extract the main content between navigation elements"""
    # Look for the pattern: <DIV then CLASS="SECT1" on separate lines
    pattern = r'<DIV\s*\n\s*CLASS="SECT1"'
    match = re.search(pattern, content)
    if not match:
        return ""

    main_start = match.start()

    # Find where this content section ends
    next_section = content.find('<DIV', main_start + 1)
    if next_section == -1:
        next_section = len(content)

    return content[main_start:next_section]

def convert_html_to_markdown(html_content):
    """Convert HTML content to markdown"""

    # Extract main content
    content = extract_section_content(html_content)

    if not content:
        return ""

    # Remove the opening SECT1 div (may span multiple lines)
    content = re.sub(r'<DIV\s*\n\s*CLASS="SECT1">\n?', '', content, flags=re.DOTALL)

    # Convert H1 headers
    def h1_to_markdown(match):
        title = clean_text(match.group(1))
        return f"\n\n## {title}\n\n"

    content = re.sub(r'<H1\s*\n\s*CLASS="SECT1">\n?\s*<A\s+NAME="[^"]*">\s*([^<]+)\s*</A>\s*</H1>', h1_to_markdown, content, flags=re.DOTALL)

    # Convert H2 headers
    def h2_to_markdown(match):
        title = clean_text(match.group(1))
        return f"\n\n### {title}\n\n"

    content = re.sub(r'<H2\s*\n\s*CLASS="SECT2">\n?\s*<A\s+NAME="[^"]*">\s*([^<]+)\s*</A>\s*</H2>', h2_to_markdown, content, flags=re.DOTALL)

    # Convert PRE blocks with SCREEN class to Pike code blocks
    def pre_screen_to_code(match):
        code_content = match.group(1)

        # Remove font and span tags with styling
        code_content = re.sub(r'<font[^>]*>.*?</font>', '', code_content, flags=re.DOTALL)
        code_content = re.sub(r'<span[^>]*>.*?</span>', '', code_content, flags=re.DOTALL)
        code_content = re.sub(r'<font[^>]*>', '', code_content)
        code_content = re.sub(r'</font>', '', code_content)

        # Clean up the code
        code_content = html.unescape(code_content)
        code_content = clean_text(code_content)

        return f"\n\n```pike\n{code_content}\n```\n"

    content = re.sub(r'<PRE\s*\n\s*CLASS="SCREEN">(.*?)</PRE>', pre_screen_to_code, content, flags=re.DOTALL)

    # Convert other PRE blocks
    def pre_to_code(match):
        code_content = match.group(1)
        code_content = html.unescape(code_content)
        code_content = clean_text(code_content)
        return f"\n\n```\n{code_content}\n```\n"

    content = re.sub(r'<PRE>(.*?)</PRE>', pre_to_code, content, flags=re.DOTALL)

    # Convert paragraphs
    content = re.sub(r'<P>(.*?)</P>', r'\n\1\n', content, flags=re.DOTALL)

    # Convert line breaks
    content = re.sub(r'<BR>', '\n', content)

    # Clean up remaining tags
    content = re.sub(r'<[^>]+>', '', content)

    # Clean up extra whitespace
    content = re.sub(r'\n\s*\n\s*\n', '\n\n', content)
    content = re.sub(r'^\s+', '', content, flags=re.MULTILINE)
    content = re.sub(r'\s+$', '', content, flags=re.MULTILINE)

    return content.strip()

def html_to_markdown(html_file_path, md_file_path):
    """Main conversion function"""

    # Read HTML file
    with open(html_file_path, 'r', encoding='utf-8') as f:
        html_content = f.read()

    # Remove HEAD section completely
    head_start = html_content.find('<HEAD')
    if head_start != -1:
        head_end = html_content.find('</HEAD>', head_start)
        if head_end != -1:
            html_content = html_content[:head_start] + html_content[head_end + 7:]

    # Remove navigation elements
    html_content = re.sub(r'<DIV\s*\n\s*CLASS="NAVHEADER">.*?</DIV>', '', html_content, flags=re.DOTALL)
    html_content = re.sub(r'<HR\s+ALIGN="LEFT"\s+WIDTH="100%">', '', html_content)
    html_content = re.sub(r'<DIV\s*\n\s*CLASS="NAVFOOTER">.*?</DIV>', '', html_content, flags=re.DOTALL)

    # Remove navigation links
    html_content = re.sub(r'<TD><A\s+HREF=".*?">Next</A></TD>', '', html_content)
    html_content = re.sub(r'<TD><A\s+HREF=".*?">Previous</A></TD>', '', html_content)
    html_content = re.sub(r'<TD><A\s+HREF=".*?">Home</A></TD>', '', html_content)

    # Remove style attributes and classes
    html_content = re.sub(r'CLASS="[^"]*"', '', html_content)
    html_content = re.sub(r'STYLE="[^"]*"', '', html_content)

    # Convert HTML to markdown
    markdown_content = convert_html_to_markdown(html_content)

    # Add frontmatter
    frontmatter = """---
id: directories
title: Directories
sidebar_label: Directories
---

"""

    final_content = frontmatter + markdown_content

    # Write the result
    with open(md_file_path, 'w', encoding='utf-8') as f:
        f.write(final_content)

if __name__ == '__main__':
    html_to_markdown('/home/smuks/OpenCode/pike-cookbook/pleac_pike/directories.html',
                    '/home/smuks/OpenCode/pike-cookbook/docs/files/directories.md')