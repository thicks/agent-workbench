#!/usr/bin/env python3
"""M4: one skill name, one body. Fail if two files claim the same name and differ or duplicate."""
from __future__ import annotations

import re
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def frontmatter_name_and_body(path: Path) -> tuple[str | None, str]:
    text = path.read_text()
    match = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.S)
    if not match:
        body = text
        name = None
        h1 = re.search(r"^# (.+)$", text, re.M)
        if h1:
            name = h1.group(1).strip().lower()
        return name, body
    front, body = match.group(1), match.group(2)
    name_m = re.search(r"^name:\s*(.+)$", front, re.M)
    name = name_m.group(1).strip().strip('"').strip("'") if name_m else None
    return name, body.lstrip("\n")


def collect() -> dict[str, list[tuple[Path, str]]]:
    by_name: dict[str, list[tuple[Path, str]]] = defaultdict(list)
    for path in sorted(ROOT.glob("skills/*.md")):
        name, body = frontmatter_name_and_body(path)
        key = name or path.stem
        by_name[key].append((path, body))
    personal = ROOT / "skills-personal"
    if personal.is_dir():
        for skill_md in sorted(personal.glob("*/SKILL.md")):
            name, body = frontmatter_name_and_body(skill_md)
            key = name or skill_md.parent.name
            by_name[key].append((skill_md, body))
    return by_name


def main() -> int:
    errors = []
    for key, copies in collect().items():
        if len(copies) < 2:
            continue
        bodies = {body for _, body in copies}
        paths = ", ".join(str(p.relative_to(ROOT)) for p, _ in copies)
        if len(bodies) == 1:
            errors.append(f"M4 duplicate identical copies of {key}: {paths}")
        else:
            errors.append(f"M4 diverged copies of {key}: {paths}")
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print("PASS: no duplicated skill/agent names")
    return 0


if __name__ == "__main__":
    sys.exit(main())
