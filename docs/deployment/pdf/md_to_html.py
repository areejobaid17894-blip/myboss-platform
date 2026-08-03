#!/usr/bin/env python3
"""Convert my boss app deployment markdown guides to styled HTML for PDF export."""
from __future__ import annotations

import html
import re
import sys
from pathlib import Path

CSS = """
@page { margin: 2cm; size: A4; }
* { box-sizing: border-box; }
body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  color: #1a1a1a; line-height: 1.55; max-width: 900px; margin: 0 auto;
  padding: 2rem; font-size: 11pt;
}
h1 { color: #ff7900; font-size: 22pt; border-bottom: 3px solid #ff7900; padding-bottom: 0.4rem; }
h2 { color: #e56a00; font-size: 14pt; margin-top: 1.8rem; page-break-after: avoid; }
h3 { font-size: 12pt; margin-top: 1.2rem; }
table { width: 100%; border-collapse: collapse; margin: 1rem 0; font-size: 10pt; page-break-inside: avoid; }
th, td { border: 1px solid #ddd; padding: 0.5rem 0.65rem; text-align: left; }
th { background: #fff3e8; color: #c45a00; }
tr:nth-child(even) { background: #fafafa; }
pre, code { font-family: 'Courier New', Courier, monospace; font-size: 9pt; }
pre {
  background: #f8f9fa; border: 1px solid #e5e7eb; border-radius: 8px;
  padding: 1rem; overflow-x: auto; page-break-inside: avoid;
}
code { background: #f3f4f6; padding: 0.1rem 0.35rem; border-radius: 4px; }
ul, ol { padding-left: 1.4rem; }
li { margin: 0.25rem 0; }
hr { border: none; border-top: 1px solid #e5e7eb; margin: 1.5rem 0; }
.footer { margin-top: 2rem; font-size: 9pt; color: #666; font-style: italic; }
"""


def md_to_html(md: str) -> str:
    lines = md.splitlines()
    out: list[str] = []
    i = 0
    in_code = False
    code_buf: list[str] = []
    in_table = False
    table_rows: list[str] = []

    def flush_table():
        nonlocal in_table, table_rows
        if not table_rows:
            return
        out.append("<table>")
        for ri, row in enumerate(table_rows):
            cells = [c.strip() for c in row.strip("|").split("|")]
            tag = "th" if ri == 0 else "td"
            out.append("<tr>" + "".join(f"<{tag}>{inline(c)}</{tag}>" for c in cells) + "</tr>")
        out.append("</table>")
        table_rows = []
        in_table = False

    def inline(text: str) -> str:
        text = html.escape(text)
        text = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", text)
        text = re.sub(r"`([^`]+)`", r"<code>\1</code>", text)
        return text

    while i < len(lines):
        line = lines[i]

        if line.strip().startswith("```"):
            if in_code:
                out.append("<pre><code>" + html.escape("\n".join(code_buf)) + "</code></pre>")
                code_buf = []
                in_code = False
            else:
                flush_table()
                in_code = True
            i += 1
            continue

        if in_code:
            code_buf.append(line)
            i += 1
            continue

        if line.strip().startswith("|"):
            if not in_table:
                in_table = True
            if re.match(r"^\|[-| :]+\|$", line.strip()):
                i += 1
                continue
            table_rows.append(line)
            i += 1
            continue
        elif in_table:
            flush_table()

        if line.strip() == "---":
            out.append("<hr/>")
        elif line.startswith("# "):
            out.append(f"<h1>{inline(line[2:])}</h1>")
        elif line.startswith("## "):
            out.append(f"<h2>{inline(line[3:])}</h2>")
        elif line.startswith("### "):
            out.append(f"<h3>{inline(line[4:])}</h3>")
        elif line.startswith("- [ ] "):
            out.append(f"<p>☐ {inline(line[6:])}</p>")
        elif line.startswith("- [x] ") or line.startswith("- [X] "):
            out.append(f"<p>☑ {inline(line[6:])}</p>")
        elif line.startswith("- "):
            out.append(f"<ul><li>{inline(line[2:])}</li></ul>")
        elif re.match(r"^\d+\.\s", line):
            content = re.sub(r"^\d+\.\s", "", line)
            out.append(f"<ol><li>{inline(content)}</li></ol>")
        elif line.strip().startswith(">"):
            out.append(f"<p><em>{inline(line.strip().lstrip('>').strip())}</em></p>")
        elif line.strip() == "":
            pass
        else:
            out.append(f"<p>{inline(line)}</p>")

        i += 1

    if in_table:
        flush_table()
    if in_code and code_buf:
        out.append("<pre><code>" + html.escape("\n".join(code_buf)) + "</code></pre>")

    return "\n".join(out)


def convert_file(md_path: Path, html_path: Path) -> None:
    body = md_to_html(md_path.read_text(encoding="utf-8"))
    title = md_path.stem.replace("_", " ")
    doc = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>{html.escape(title)}</title>
  <style>{CSS}</style>
</head>
<body>
{body}
<p class="footer">Orange — my boss app — Generated from {md_path.name}</p>
</body>
</html>"""
    html_path.write_text(doc, encoding="utf-8")
    print(f"  HTML: {html_path.name}")


def main() -> int:
    pdf_dir = Path(__file__).resolve().parent
    # Canonical guides (full content) → numbered HTML for PDF export
    canonical = [
        (pdf_dir / "../../devops/DEVOPS.md", pdf_dir / "01_DEVOPS_INSTALLATION.html"),
        (pdf_dir / "../../mobile/ANDROID_STUDIO.md", pdf_dir / "05_ANDROID_STUDIO_MOBILE.html"),
        (pdf_dir / "../../security/SECURITY.md", pdf_dir / "06_SECURITY.html"),
        (pdf_dir / "../../database/DATABASE.md", pdf_dir / "07_DATABASE.html"),
    ]
    md_files = sorted(pdf_dir.glob("*.md"))
    md_files = [f for f in md_files if f.name != "README.md"]

    if not md_files and not canonical:
        print("No markdown files found.")
        return 1

    print("Converting markdown → HTML...")
    for md in md_files:
        convert_file(md, md.with_suffix(".html"))
    for src, html_out in canonical:
        if src.resolve().is_file():
            convert_file(src.resolve(), html_out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
