#!/usr/bin/env python3
"""M5/M7: docs match the tree; relative links resolve; commands/agents name real skills."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

LINK_RE = re.compile(r"\[([^\]]+)\]\(([^)]+)\)")

COMMAND_SKILLS = {
    "incept.md": "incept",
    "discover.md": "tech-discovery",
    "design.md": "tech-incept",
    "plan.md": "write-plan",
    "execute.md": "execute-plan",
    "implement.md": "tech-incept",
}


def skill_names() -> set[str]:
    names = {p.stem for p in (ROOT / "skills").glob("*.md")}
    personal = ROOT / "skills-personal"
    if personal.is_dir():
        names |= {p.parent.name for p in personal.glob("*/SKILL.md")}
    return names


def check_forbidden() -> list[str]:
    errors = []
    if (ROOT / "adapters" / "claude" / "skills").exists():
        errors.append("M5: adapters/claude/skills/ must not exist; frontmatter lives in skills/*.md")
    if (ROOT / "adapters" / "Codex").exists():
        errors.append("M5: adapters/Codex/ does not exist; use adapters/opencode/")
    example = ROOT / "adapters" / "claude" / "settings.local.json.example"
    if "thickideas" in example.read_text() or "/Users/" in example.read_text():
        errors.append("M8: settings.local.json.example must not ship a personal path")
    for rel in ("CLAUDE.md", "docs/architecture.md", "AGENTS.md"):
        text = (ROOT / rel).read_text()
        if re.search(r"Edit `adapters/.+header\.md`", text):
            errors.append(f"{rel}: still tells contributors to edit *.header.md")
        if re.search(r"lives at `adapters/Codex/`", text):
            errors.append(f"{rel}: still claims a Codex adapter tree")
    return errors


def check_links() -> list[str]:
    errors = []
    roots = [
        ROOT / "README.md",
        ROOT / "CLAUDE.md",
        ROOT / "AGENTS.md",
        ROOT / "docs",
        ROOT / "references",
        ROOT / "adapters",
    ]
    files: list[Path] = []
    for item in roots:
        if item.is_file():
            files.append(item)
        elif item.is_dir():
            files.extend(item.rglob("*.md"))
    for path in files:
        text = path.read_text()
        for match in LINK_RE.finditer(text):
            url = match.group(2).split()[0].strip("<>")
            if url.startswith(("http://", "https://", "mailto:", "obsidian://", "#")):
                continue
            url = url.split("#", 1)[0]
            if not url:
                continue
            dest = (path.parent / url).resolve()
            try:
                dest.relative_to(ROOT.resolve())
            except ValueError:
                continue
            if not dest.exists():
                errors.append(f"{path.relative_to(ROOT)}: broken link {url}")
    return errors


def check_commands_and_agents() -> list[str]:
    errors = []
    names = skill_names()
    names |= {"dev-workflow", "task-executor", "researcher", "tech-discovery-max"}
    cmd_dir = ROOT / "adapters" / "claude" / "commands"
    for cmd, skill in COMMAND_SKILLS.items():
        path = cmd_dir / cmd
        if not path.exists():
            errors.append(f"missing command {cmd}")
            continue
        text = path.read_text()
        if skill not in text:
            errors.append(f"adapters/claude/commands/{cmd}: expected to mention skill {skill}")
        if skill not in names and skill not in {"dev-workflow"}:
            errors.append(f"command {cmd} references unknown skill {skill}")
    agent = ROOT / "adapters" / "claude" / "agents" / "dev-workflow.md"
    text = agent.read_text()
    for skill in ("incept", "tech-incept", "write-plan", "execute-plan", "tech-discovery"):
        if skill not in text:
            errors.append(f"dev-workflow agent missing skill {skill}")
        if skill not in names:
            errors.append(f"dev-workflow references missing skill file {skill}")
    return errors


def main() -> int:
    errors = check_forbidden() + check_links() + check_commands_and_agents()
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print("PASS: docs, links, and command/skill map")
    return 0


if __name__ == "__main__":
    sys.exit(main())
