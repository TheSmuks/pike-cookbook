#!/usr/bin/env python3

import re
import html

def html_to_markdown(html_file_path, md_file_path):
    """Convert HTML to markdown with proper multi-line handling"""

    with open(html_file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Remove HEAD section completely
    head_start = content.find('<HEAD')
    if head_start != -1:
        head_end = content.find('</HEAD>', head_start)
        if head_end != -1:
            content = content[:head_start] + content[head_end + 7:]

    # Remove navigation elements
    content = re.sub(r'<DIV CLASS="NAVHEADER">.*?</DIV>', '', content, flags=re.DOTALL)
    content = re.sub(r'<HR ALIGN="LEFT" WIDTH="100%">', '', content)
    content = re.sub(r'<DIV CLASS="NAVFOOTER">.*?</DIV>', '', content, flags=re.DOTALL)

    # Remove navigation links
    content = re.sub(r'<TD><A HREF=".*?">Next</A></TD>', '', content)
    content = re.sub(r'<TD><A HREF=".*?">Previous</A></TD>', '', content)
    content = re.sub(r'<TD><A HREF=".*?">Home</A></TD>', '', content)

    # Remove style attributes and classes
    content = re.sub(r'CLASS="[^"]*"', '', content)
    content = re.sub(r'STYLE="[^"]*"', '', content)

    # Find start after "9. Directories" - use simpler approach
    start_pos = content.find('>9. Directories</A>')
    if start_pos == -1:
        print("Could not find Directories section")
        return

    start_pos = content.find('</H1>', start_pos) + 5  # End of H1 tag
    print(f"Found Directories section starting at position {start_pos}")

    # Find end at next major section or end of file
    end_positions = [len(content)]

    # Find next H1
    next_h1 = re.search(r'<H1 CLASS="SECT1">', content[start_pos:])
    if next_h1:
        end_positions.append(start_pos + next_h1.start())

    # Find next NAVFOOTER
    next_nav = re.search(r'<DIV CLASS="NAVFOOTER">', content[start_pos:])
    if next_nav:
        end_positions.append(start_pos + next_nav.start())

    end_pos = min(end_positions)
    print(f"Content ends at position {end_pos}")

    # Extract content
    content = content[start_pos:end_pos]

    # Convert H2 headers
    def h2_to_md(match):
        title = match.group(1)
        return f"\n### {title}\n\n"

    content = re.sub(r'<H2 CLASS="SECT2"><A NAME="[^"]*">([^<]+)</A></H2>', h2_to_md, content)

    # Convert PRE blocks with SCREEN class
    def pre_screen_to_code(match):
        code_content = match.group(1)

        # Remove font and span tags
        code_content = re.sub(r'<font[^>]*>.*?</font>', '', code_content, flags=re.DOTALL)
        code_content = re.sub(r'<span[^>]*>.*?</span>', '', code_content, flags=re.DOTALL)
        code_content = re.sub(r'<font[^>]*>', '', code_content)
        code_content = re.sub(r'</font>', '', code_content)

        # Decode HTML entities
        code_content = html.unescape(code_content)

        # Clean up whitespace
        code_content = re.sub(r'\s+', ' ', code_content).strip()

        return f"\n```pike\n{code_content}\n```\n"

    content = re.sub(r'<PRE CLASS="SCREEN">(.*?)</PRE>', pre_screen_to_code, content, flags=re.DOTALL)

    # Convert other PRE blocks
    content = re.sub(r'<PRE>(.*?)</PRE>', r'\n```\n\1\n```\n', content, flags=re.DOTALL)

    # Convert paragraphs
    content = re.sub(r'<P>(.*?)</P>', r'\n\1\n', content, flags=re.DOTALL)

    # Convert line breaks
    content = re.sub(r'<BR>', '\n', content)

    # Remove all HTML tags
    content = re.sub(r'<[^>]+>', '', content)

    # Decode HTML entities
    content = html.unescape(content)

    # Clean up extra whitespace
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

    print(f"Successfully converted {len(final_content)} characters to markdown")

if __name__ == '__main__':
    html_to_markdown('/home/smuks/OpenCode/pike-cookbook/pleac_pike/directories.html',
                    '/home/smuks/OpenCode/pike-cookbook/docs/files/directories.md')