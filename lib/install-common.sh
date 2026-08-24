# Shared install helpers. Sourced by install.sh (and tests).
# shellcheck shell=bash

backup_if_exists() {
  local ts dest
  if [[ -e "$1" ]]; then
    ts="$(date +%Y%m%d%H%M%S)"
    dest="${1}.bak.${ts}"
    cp -R "$1" "$dest"
    echo "  backed up: $dest"
  fi
}

record_installed() {
  local dest rel
  dest="$1"
  [[ -n "${TARGET:-}" ]] || return 0
  [[ "${DRY_RUN:-0}" == "1" ]] && return 0
  rel="$dest"
  if [[ "$dest" == "${TARGET%/}"/* ]]; then
    rel="${dest#"${TARGET%/}"/}"
  fi
  mkdir -p "$TARGET"
  printf '%s\n' "$rel" >> "$TARGET/.agent-workbench-installed.txt"
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

  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    echo "  dry-run: $desc"
    return 0
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
  record_installed "$dest"
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

  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    echo "  dry-run: $label"
    return 0
  fi

  mkdir -p "$(dirname "$dest")" || return 1
  local tmp_file
  tmp_file=$(mktemp) || return 1
  {
    echo "---"
    printf '%s\n' "$@"
    echo "---"
    echo
    printf '%s\n' "$body"
  } > "$tmp_file" || { rm -f "$tmp_file"; return 1; }

  if [[ -e "$dest" ]]; then
    if cmp -s "$tmp_file" "$dest"; then
      echo "  unchanged: $label"
      rm -f "$tmp_file"
      return 0
    fi
    prompt_overwrite "$dest" "$label" || {
      st=$?
      rm -f "$tmp_file"
      [[ "$st" -eq 2 ]] && return 2
      return "$st"
    }
  fi

  mv "$tmp_file" "$dest" || { rm -f "$tmp_file"; return 1; }
  record_installed "$dest"
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

  if [[ "${DRY_RUN:-0}" != "1" ]]; then
    mkdir -p "$dest_dir"
  fi

  local nullglob_was=0
  shopt -q nullglob && nullglob_was=1
  shopt -s nullglob
  local src_files=("$src_dir"/*)
  if [[ "$nullglob_was" -eq 0 ]]; then
    shopt -u nullglob
  fi

  if [[ ${#src_files[@]} -eq 0 ]]; then
    return 0
  fi

  local src_file filename dest_file
  for src_file in "${src_files[@]}"; do
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
      if [[ "${DRY_RUN:-0}" == "1" ]]; then
        echo "  dry-run: $desc/$filename/"
        continue
      fi
      cp -R "$src_file" "$dest_file" || return 1
      record_installed "$dest_file"
      echo "  installed: $desc/$filename/"
    else
      ok_or_skip install_file_safe "$src_file" "$dest_file" "$desc/$filename"
    fi
  done
}
