#!/usr/bin/env bash
# Superpowers Patcher v2 (multi-anchor, section replacement)
#
# Runs on SessionStart. Scans ~/.claude/patches/ for *.patch.md files,
# matches each to a superpowers skill by filename, and applies patches.
#
# Patch file format (supports multiple blocks per file):
#
#   <!-- ANCHOR: ## Section Name -->
#   <!-- PATCH:skill-name vN -->
#   replacement content...
#
#   <!-- ANCHOR: ## Another Section -->
#   <!-- PATCH:skill-name vN -->
#   replacement content...
#
# Heading anchors (## ...) → REPLACE: replaces from anchor to next same-level heading
# Non-heading anchors → INSERT: injects after the anchor line
#
# Uses .orig backup for idempotent restore-and-reapply on every session.
# Outputs nothing to stdout (zero token consumption).

set -euo pipefail

PATCHES_DIR="$HOME/.claude/patches"
PLUGINS_CACHE="$HOME/.claude/plugins/cache/claude-plugins-official/superpowers"

find_latest_version() {
  [ -d "$PLUGINS_CACHE" ] || return 1
  ls -1 "$PLUGINS_CACHE" | sort -V | tail -1
}

# Restore from .orig backup, or create one if file is clean.
# Returns 1 if file is patched without backup (needs migration).
ensure_original() {
  local skill_file="$1"
  local orig_file="${skill_file}.orig"

  if [ -f "$orig_file" ]; then
    cp "$orig_file" "$skill_file"
    return 0
  fi

  if grep -q "<!-- PATCH:" "$skill_file" 2>/dev/null; then
    return 1
  fi

  cp "$skill_file" "$orig_file"
  return 0
}

# Parse patch file into block files under tmpdir.
# Each block: N.anchor, N.content, N.mode, N.level
# Prints block count to stdout.
parse_blocks() {
  local patch_file="$1"
  local tmpdir="$2"
  local idx=-1
  local has_marker=false

  while IFS= read -r line || [ -n "$line" ]; do
    if [[ "$line" == *"<!-- ANCHOR:"*"-->"* ]]; then
      idx=$((idx + 1))
      local anchor
      anchor=$(echo "$line" | sed -n 's/.*<!-- ANCHOR: \(.*\) -->.*/\1/p')
      printf '%s' "$anchor" > "$tmpdir/${idx}.anchor"
      : > "$tmpdir/${idx}.content"
      has_marker=false

      if [[ "$anchor" == \#* ]]; then
        printf 'replace' > "$tmpdir/${idx}.mode"
        local hashes="${anchor%%[^#]*}"
        printf '%s' "${#hashes}" > "$tmpdir/${idx}.level"
      else
        printf 'insert' > "$tmpdir/${idx}.mode"
        printf '0' > "$tmpdir/${idx}.level"
      fi
      continue
    fi

    if [[ "$line" == *"<!-- PATCH:"*"-->"* ]] && [ "$has_marker" = false ] && [ "$idx" -ge 0 ]; then
      has_marker=true
      # Write ANCHOR + PATCH comment lines into content as markers
      local anchor
      anchor=$(cat "$tmpdir/${idx}.anchor")
      printf '<!-- ANCHOR: %s -->\n' "$anchor" >> "$tmpdir/${idx}.content"
      printf '%s\n' "$line" >> "$tmpdir/${idx}.content"
      continue
    fi

    if [ "$idx" -ge 0 ] && [ "$has_marker" = true ]; then
      printf '%s\n' "$line" >> "$tmpdir/${idx}.content"
    fi
  done < "$patch_file"

  echo $((idx + 1))
}

# Apply parsed blocks to a skill file.
apply_blocks() {
  local skill_file="$1"
  local tmpdir="$2"
  local num_blocks="$3"

  # Pre-load block data into arrays
  local -a anchors modes levels
  for ((i=0; i<num_blocks; i++)); do
    anchors[$i]=$(cat "$tmpdir/${i}.anchor")
    modes[$i]=$(cat "$tmpdir/${i}.mode")
    levels[$i]=$(cat "$tmpdir/${i}.level")
  done

  local outfile
  outfile=$(mktemp)
  local skip_mode=false
  local skip_level=0

  while IFS= read -r line || [ -n "$line" ]; do
    # In skip mode: wait for next heading at same or higher level
    if [ "$skip_mode" = true ]; then
      if [[ "$line" =~ ^(#+)[[:space:]] ]]; then
        local this_level=${#BASH_REMATCH[1]}
        if [ "$this_level" -le "$skip_level" ]; then
          skip_mode=false
          # Fall through to normal processing below
        else
          continue
        fi
      else
        continue
      fi
    fi

    # Check if line matches any block's anchor
    local matched=false
    for ((i=0; i<num_blocks; i++)); do
      local escaped
      escaped=$(printf '%s' "${anchors[$i]}" | sed 's/[][*.\\/^${}()|+?]/\\&/g')

      if printf '%s' "$line" | grep -q "$escaped" 2>/dev/null; then
        # Output the anchor line (heading / list item)
        printf '%s\n' "$line" >> "$outfile"
        printf '\n' >> "$outfile"
        # Output patch content
        cat "$tmpdir/${i}.content" >> "$outfile"

        if [ "${modes[$i]}" = "replace" ]; then
          skip_mode=true
          skip_level=${levels[$i]}
        fi

        matched=true
        break
      fi
    done

    if [ "$matched" = false ]; then
      printf '%s\n' "$line" >> "$outfile"
    fi
  done < "$skill_file"

  cp "$outfile" "$skill_file"
  rm -f "$outfile"
}

# --- Main ---

VERSION=$(find_latest_version) || exit 0
SKILLS_DIR="${PLUGINS_CACHE}/${VERSION}/skills"

[ -d "$PATCHES_DIR" ] || exit 0

# Migration: if any skill file has PATCH markers but no .orig backup,
# the old patcher applied patches without backup. Delete the version
# directory to force plugin reinstall with clean files.
for patch_file in "${PATCHES_DIR}"/*.patch.md; do
  [ -f "$patch_file" ] || continue
  skill_name=$(basename "$patch_file" .patch.md)
  skill_file="${SKILLS_DIR}/${skill_name}/SKILL.md"
  [ -f "$skill_file" ] || continue

  if grep -q "<!-- PATCH:" "$skill_file" 2>/dev/null && [ ! -f "${skill_file}.orig" ]; then
    rm -rf "${PLUGINS_CACHE}/${VERSION}"
    exit 0
  fi
done

# Apply patches
for patch_file in "${PATCHES_DIR}"/*.patch.md; do
  [ -f "$patch_file" ] || continue

  skill_name=$(basename "$patch_file" .patch.md)
  skill_file="${SKILLS_DIR}/${skill_name}/SKILL.md"
  [ -f "$skill_file" ] || continue

  # Restore from .orig or create .orig
  ensure_original "$skill_file" || continue

  # Parse and apply
  tmpdir=$(mktemp -d)
  num_blocks=$(parse_blocks "$patch_file" "$tmpdir")

  if [ "$num_blocks" -gt 0 ]; then
    apply_blocks "$skill_file" "$tmpdir" "$num_blocks"
  fi

  rm -rf "$tmpdir"
done

exit 0
