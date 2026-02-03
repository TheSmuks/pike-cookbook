#!/usr/bin/env python3

import re
import html
from pathlib import Path

def html_to_markdown(html_file_path, md_file_path):
    with open(html_file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Remove DOCTYPE and <HTML> tags
    content = re.sub(r'<!DOCTYPE.*?>', '', content, flags=re.DOTALL)
    content = re.sub(r'<HTML>', '', content, flags=re.DOTALL)
    content = re.sub(r'</HTML>', '', content, flags=re.DOTALL)

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
    content = re.sub(r'<TD><A HREF=".*?" ACCESSKEY="N">Next</A></TD>', '', content, flags=re.DOTALL)
    content = re.sub(r'<TD><A HREF=".*?" ACCESSKEY="P">Previous</A></TD>', '', content, flags=re.DOTALL)
    content = re.sub(r'<TD><A HREF=".*?" ACCESSKEY="H">Home</A></TD>', '', content, flags=re.DOTALL)

    # Remove style attributes and classes
    content = re.sub(r'CLASS="[^"]*"', '', content)
    content = re.sub(r'STYLE="[^"]*"', '', content)

    # Find section content structure
    # Look for main content between opening DIV and before navigation
    main_start = content.find('<DIV CLASS="SECT1">')
    if main_start != -1:
        # Find where the actual content ends (before navigation footer)
        nav_start = content.find('<DIV CLASS="NAVFOOTER">', main_start)
        if nav_start != -1:
            content = content[main_start:nav_start]

    # Convert headers
    content = re.sub(r'<H1 CLASS="SECT1"><A NAME="[^"]*">([^<]+)</A></H1>', r'## \1', content)
    content = re.sub(r'<H2 CLASS="SECT2"><A NAME="[^"]*">([^<]+)</A></H2>', r'### \1', content)

    # Convert PRE tags with SCREEN class to code blocks
    def pre_to_match(match):
        pre_content = match.group(1)
        # Clean up the HTML spans and styling
        pre_content = re.sub(r'<font[^>]*>.*?</font>', '', pre_content, flags=re.DOTALL)
        pre_content = re.sub(r'<span[^>]*>.*?</span>', '', pre_content, flags=re.DOTALL)
        # Remove inline styles
        pre_content = re.sub(r'<font[^>]*>', '', pre_content)
        pre_content = re.sub(r'</font>', '', pre_content)
        pre_content = html.unescape(pre_content)
        return f"\n\n```pike\n{pre_content.strip()}\n```\n"

    content = re.sub(r'<PRE CLASS="SCREEN">(.*?)</PRE>', pre_to_match, content, flags=re.DOTALL)

    # Convert other PRE tags to code blocks
    content = re.sub(r'<PRE>(.*?)</PRE>', r'\n\n```\n\1\n```\n', content, flags=re.DOTALL)

    # Convert paragraphs
    content = re.sub(r'<P>(.*?)</P>', r'\n\1\n', content, flags=re.DOTALL)

    # Convert line breaks
    content = re.sub(r'<BR>', '\n', content)

    # Convert entity references
    content = html.unescape(content)

    # Clean up remaining tags
    content = re.sub(r'<[^>]+>', '', content)

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

if __name__ == '__main__':
    html_to_markdown('/home/smuks/OpenCode/pike-cookbook/pleac_pike/directories.html',
                    '/home/smuks/OpenCode/pike-cookbook/docs/files/directories.md')