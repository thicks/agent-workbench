# Skills Personal

A manifest-based system for managing external skills without copying them into your repository.

## Structure

- **manifest.json** — JSON list of skills you like, with repo and file references
- **install.sh** — Script to parse the manifest and interactively install skills

## Adding a Skill

Edit `manifest.json` and add an entry:

```json
{
  "skill": "skill-name",
  "repo": "https://github.com/owner/repo",
  "file": "path/to/skill-name.md",
  "description": "What this skill does",
  "tags": ["category", "relevant-tags"]
}
```

## Installing Skills

Run the install script:

```bash
./install.sh
```

The script will:
1. Read each skill from the manifest
2. Show the description and source
3. Prompt you to install each one
4. Clone the repo and copy the skill file to `./skills/`

You can also set a target directory:

```bash
SKILLS_DIR=/path/to/skills ./install.sh
```

## Why This Approach?

- **Lightweight:** No duplication; skills stay in their original repos
- **Discoverable:** One manifest file lists all candidates
- **Safe:** Prompts before installing each skill
- **Flexible:** Easy to add/remove candidates without cloning
