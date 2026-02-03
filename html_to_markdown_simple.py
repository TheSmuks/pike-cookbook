#!/usr/bin/env python3

import re
import html

def html_to_markdown(html_file_path, md_file_path):
    """Convert HTML to markdown with minimal processing"""

    # Read HTML file
    with open(html_file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Remove HEAD section
    head_start = content.find('<HEAD')
    if head_start != -1:
        head_end = content.find('</HEAD>', head_start)
        if head_end != -1:
            content = content[:head_start] + content[head_end + 7:]

    # Remove navigation elements
    content = re.sub(r'<DIV CLASS="NAVHEADER">.*?</DIV>', '', content, flags=re.DOTALL)
    content = re.sub(r'<HR ALIGN="LEFT" WIDTH="100%">', '', content)
    content = re.sub(r'<DIV CLASS="NAVFOOTER">.*?</DIV>', '', content, flags=re.DOTALL)

    # Find and extract main content (from "9. Directories" to before next major section)
    directories_start = content.find('9. Directories')
    if directories_start == -1:
        directories_start = content.find('Directories')

    if directories_start == -1:
        print("Could not find Directories section")
        return

    # Find end of content (before next major section or end)
    # Look for next major heading
    next_h1 = content.find('<H1', directories_start + 1)
    next_h2 = content.find('<H2', directories_start + 1)
    next_div = content.find('<DIV CLASS="NAVFOOTER">', directories_start + 1)

    end_positions = [len(content)]
    if next_h1 != -1:
        end_positions.append(next_h1)
    if next_h2 != -1:
        end_positions.append(next_h2)
    if next_div != -1:
        end_positions.append(next_div)

    content_end = min(end_positions)

    # Extract just the content we want
    content = content[directories_start:content_end]

    # Convert headers
    def h1_to_md(match):
        title = match.group(1)
        return f"\n\n## {title}\n\n"

    def h2_to_md(match):
        title = match.group(1)
        return f"\n\n### {title}\n\n"

    content = re.sub(r'<H1 CLASS="SECT1"><A NAME="[^"]*">([^<]+)</A></H1>', h1_to_md, content)
    content = re.sub(r'<H2 CLASS="SECT2"><A NAME="[^"]*">([^<]+)</A></H2>', h2_to_md, content)

    # Convert code blocks
    def pre_to_code(match):
        code = match.group(1)
        # Remove font and span tags
        code = re.sub(r'<font[^>]*>.*?</font>', '', code, flags=re.DOTALL)
        code = re.sub(r'<span[^>]*>.*?</span>', '', code, flags=re.DOTALL)
        code = re.sub(r'<font[^>]*>', '', code)
        code = re.sub(r'</font>', '', code)
        # Decode HTML entities
        code = html.unescape(code)
        # Clean whitespace
        code = re.sub(r'\s+', ' ', code).strip()
        return f"\n\n```pike\n{code}\n```\n"

    content = re.sub(r'<PRE CLASS="SCREEN">(.*?)</PRE>', pre_to_code, content, flags=re.DOTALL)
    content = re.sub(r'<PRE>(.*?)</PRE>', r'\n\n```\n\1\n```\n', content, flags=re.DOTALL)

    # Convert paragraphs
    content = re.sub(r'<P>(.*?)</P>', r'\n\1\n', content, flags=re.DOTALL)

    # Convert line breaks
    content = re.sub(r'<BR>', '\n', content)

    # Remove all HTML tags
    content = re.sub(r'<[^>]+>', '', content)

    # Clean up HTML entities
    content = html.unescape(content)

    # Clean up whitespace
    content = re.sub(r'\n\s*\n\s*\n', '\n\n', content)
    content = re.sub(r'^\s+', '', content, flags=re.MULTILINE)
    content = re.sub(r'\s+$', '', content, flags=re.MULTILINE)

    # Add frontmatter
    frontmatter = """---
id: directories
title: Directories
sidebar_label: Directories
---

"""

    final_content = frontmatter + content.strip()

    # Write the result
    with open(md_file_path, 'w', encoding='utf-8') as f:
        f.write(final_content)

    print(f"Converted {len(final_content)} characters to markdown")

if __name__ == '__main__':
    html_to_markdown('/home/smuks/OpenCode/pike-cookbook/pleac_pike/directories.html',
                    '/home/smuks/OpenCode/pike-cookbook/docs/files/directories.md')