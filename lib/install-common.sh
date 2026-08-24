# Shared install helpers. Sourced by install.sh (and tests).
# shellcheck shell=bash

backup_if_exists() {
  if [[ -e "$1" ]]; then
    cp -R "$1" "${1}.bak"
    echo "  backed up: $1"
  fi
}

prompt_overwrite() {
  local target="$1"
  local description="$2"
  echo "  ⚠ $description already exists at $target"
  if [[ "${NONINTERACTIVE:-0}" == "1" ]]; then
    return 0
  fi
  read -rp "  Overwrite? [y/N/b=backup only] " resp
  case "$resp" in
    [Yy]) return 0 ;;
    [Bb]) backup_if_exists "$target"; return 2 ;;
    *) echo "  skipped"; return 2 ;;
  esac
}

# 0 = installed/unchanged, 2 = user skipped, 1 = real failure.
# Skip must not trip set -e at bare call sites.
ok_or_skip() {
  local st=0
  "$@" || st=$?
  [[ "$st" -eq 0 || "$st" -eq 2 ]]
}

install_file_safe() {
  local src="$1"
  local dest="$2"
  local desc
  desc="${3:-$(basename "$dest")}"
  local st=0

  if [[ ! -f "$src" ]]; then
    echo "  missing source: $src" >&2
    return 1
  fi

  if [[ -e "$dest" ]]; then
    if cmp -s "$src" "$dest"; then
      echo "  unchanged: $desc"
      return 0
    fi
    prompt_overwrite "$dest" "$desc" || {
      st=$?
      [[ "$st" -eq 2 ]] && return 2
      return "$st"
    }
  fi

  mkdir -p "$(dirname "$dest")" || return 1
  cp "$src" "$dest" || return 1
  echo "  installed: $desc"
}

skill_field() {
  local file="$1" field="$2"
  awk -v f="$field" '
    /^---$/ { c++; next }
    c==1 && $0 ~ "^" f ":" {
      sub("^" f ": *", "", $0)
      print $0
      exit
    }
  ' "$file"
}

skill_body() {
  # Drop only the opening YAML frontmatter (first two --- lines). Later ---
  # lines are section rules or fenced examples and must be kept so tools still
  # see a single leading frontmatter pair plus the original body.
  awk '
    /^---$/ && done == 0 {
      c++
      if (c == 2) done = 1
      next
    }
    done { print }
  ' "$1" | sed '/./,$!d'
}

# write_skill <dest> <label> <body> <frontmatter-line>...
write_skill() {
  local dest="$1" label="$2" body="$3"; shift 3
  local st=0

  mkdir -p "$(dirname "$dest")" || return 1
  local tmp_file
  tmp_file=$(mktemp)
  {
    echo "---"
    printf '%s\n' "$@"
    echo "---"
    echo
    printf '%s\n' "$body"
  } > "$tmp_file"

  if [[ -e "$dest" ]]; then
    if cmp -s "$tmp_file" "$dest"; then
      echo "  unchanged: $label"
      rm "$tmp_file"
      return 0
    fi
    prompt_overwrite "$dest" "$label" || {
      st=$?
      rm -f "$tmp_file"
      [[ "$st" -eq 2 ]] && return 2
      return "$st"
    }
  fi

  mv "$tmp_file" "$dest" || return 1
  echo "  rendered: $label"
}

install_dir_safe() {
  local src_dir="$1"
  local dest_dir="$2"
  local desc="$3"
  local st=0

  if [[ ! -d "$src_dir" ]]; then
    return 0
  fi

  mkdir -p "$dest_dir"

  for src_file in "$src_dir"/*; do
    local filename dest_file
    filename="$(basename "$src_file")"
    dest_file="$dest_dir/$filename"

    if [[ -d "$src_file" ]]; then
      if [[ -d "$dest_file" ]]; then
        st=0
        prompt_overwrite "$dest_file" "$desc/$filename" || st=$?
        # Skip and backup-only must not merge new files into the existing dir
        # (M2: a declined overwrite is not a merge).
        if [[ "$st" -eq 2 ]]; then
          continue
        elif [[ "$st" -ne 0 ]]; then
          return "$st"
        fi
        rm -rf "$dest_file"
      fi
      cp -R "$src_file" "$dest_file" || return 1
      echo "  installed: $desc/$filename/"
    else
      ok_or_skip install_file_safe "$src_file" "$dest_file" "$desc/$filename"
    fi
  done
}
