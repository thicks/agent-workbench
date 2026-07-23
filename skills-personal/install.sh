#!/bin/bash

set -e

MANIFEST_FILE="$(dirname "$0")/manifest.json"
SKILLS_DIR="${SKILLS_DIR:-.}"

if [ ! -f "$MANIFEST_FILE" ]; then
  echo "Error: manifest.json not found at $MANIFEST_FILE"
  exit 1
fi

echo "📦 Skill Installation Manager"
echo "========================================"
echo ""

# Read manifest and iterate through skills
jq -r '.skills[] | @base64' "$MANIFEST_FILE" | while read skill_b64; do
  skill=$(echo "$skill_b64" | base64 -d)

  skill_name=$(echo "$skill" | jq -r '.skill')
  repo=$(echo "$skill" | jq -r '.repo')
  file=$(echo "$skill" | jq -r '.file')
  description=$(echo "$skill" | jq -r '.description // "No description"')

  echo "🔹 $skill_name"
  echo "   $description"
  echo "   📍 $repo / $file"
  echo ""

  read -p "   Install? (y/n/skip) " -n 1 -r
  echo

  case $REPLY in
    y|Y)
      echo "   → Installing $skill_name..."

      # Create temp directory
      temp_dir=$(mktemp -d)
      trap "rm -rf $temp_dir" EXIT

      # Clone repo
      git clone --depth 1 "$repo" "$temp_dir" 2>/dev/null || {
        echo "   ✗ Failed to clone $repo"
        continue
      }

      # Copy skill file
      if [ -f "$temp_dir/$file" ]; then
        mkdir -p "$SKILLS_DIR/$(dirname "$file")"
        cp "$temp_dir/$file" "$SKILLS_DIR/$file"
        echo "   ✓ Installed to $SKILLS_DIR/$file"
      else
        echo "   ✗ File not found: $file in $repo"
      fi
      echo ""
      ;;
    n|N)
      echo "   → Skipped"
      echo ""
      ;;
    *)
      echo "   → Skipped"
      echo ""
      ;;
  esac
done

echo "✨ Installation complete!"
