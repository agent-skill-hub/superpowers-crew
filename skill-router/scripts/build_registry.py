#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Build registry.csv from agent/skill .md files with YAML frontmatter.
Usage:
    python build_registry.py                          # default: scan crew-archive
    python build_registry.py --dir ~/.claude/crew-archive --type agent
"""

import csv
import os
import sys
import argparse
import yaml
from pathlib import Path

DATA_DIR = Path(__file__).parent.parent / "data"
REGISTRY = DATA_DIR / "registry.csv"
DEFAULT_ARCHIVE = Path.home() / ".claude" / "crew-archive"


def extract_frontmatter(filepath):
    """Parse YAML frontmatter from .md file, returns full dict."""
    text = filepath.read_text(encoding="utf-8")
    if not text.startswith("---"):
        return None
    end = text.find("\n---", 3)
    if end == -1:
        return None
    try:
        return yaml.safe_load(text[3:end])
    except yaml.YAMLError:
        # Fallback: regex extraction for files with unquoted special chars
        import re
        fm = text[3:end]
        result = {}
        for key in ("name", "description"):
            m = re.search(rf'^{key}:\s*(.+)$', fm, re.MULTILINE)
            if m:
                result[key] = m.group(1).strip().strip('"').strip("'")
        return result if result else None


def scan_directory(directory, entry_type="agent"):
    """Scan directory for .md files, extract metadata. Follows symlinks."""
    entries = []
    md_files = []
    for root, dirs, files in os.walk(directory, followlinks=True):
        for f in sorted(files):
            if f.endswith(".md") and f != "README.md":
                md_files.append(Path(root) / f)
    for md_file in sorted(md_files):
        fm = extract_frontmatter(md_file)
        if not fm:
            continue
        name = fm.get("name", md_file.stem)
        description = fm.get("description", "")
        keywords = fm.get("keywords", "")
        # Normalize multiline description to single string
        if isinstance(description, list):
            description = " ".join(description)
        description = str(description).replace("\n", " ").strip()
        if isinstance(keywords, list):
            keywords = ", ".join(keywords)
        # Path relative with ~ prefix
        rel_path = f"~/.claude/crew-archive/{md_file.relative_to(directory)}"
        entries.append({
            "Name": str(name).strip(),
            "Type": entry_type,
            "Description": description,
            "Path": rel_path,
            "Keywords": str(keywords).strip() if keywords else "",
        })
    return entries


def main():
    parser = argparse.ArgumentParser(description="Build skill-router registry CSV")
    parser.add_argument("--dir", type=Path, default=DEFAULT_ARCHIVE, help="Directory to scan")
    parser.add_argument("--type", default="agent", help="Entry type (agent/skill)")
    parser.add_argument("--output", type=Path, default=REGISTRY, help="Output CSV path")
    args = parser.parse_args()

    entries = scan_directory(args.dir, args.type)

    with open(args.output, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["Name", "Type", "Description", "Path", "Keywords"])
        writer.writeheader()
        writer.writerows(entries)

    print(f"[OK] {len(entries)} entries -> {args.output}", flush=True)


if __name__ == "__main__":
    main()
