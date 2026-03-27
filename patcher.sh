#!/usr/bin/env bash
# Superpowers Crew Patcher (auto-discovery mode)
#
# Runs on SessionStart. Scans ~/.claude/patches/ for *.patch.md files,
# matches each to a superpowers skill by filename, and injects the patch
# content after the anchor line specified in the patch file header.
#
# Patch file format:
#   Line 1: <!-- ANCHOR: <text to match in skill file> -->
#   Line 2: <!-- PATCH:<skill-name> v<N> -->
#   Rest:   Content to inject
#
# If already patched (PATCH marker found), skips silently.
# Outputs nothing to stdout (zero token consumption).

set -euo pipefail

PATCHES_DIR="$HOME/.claude/patches"
PLUGINS_CACHE="$HOME/.claude/plugins/cache/claude-plugins-official/superpowers"

# Find the latest superpowers version directory
find_latest_version() {
  [ -d "$PLUGINS_CACHE" ] || return 1
  ls -1 "$PLUGINS_CACHE" | sort -V | tail -1
}

# Extract ANCHOR pattern from patch file (line 1)
get_anchor() {
  local patch_file="$1"
  local first_line
  first_line=$(head -1 "$patch_file")
  # Extract content between <!-- ANCHOR: and -->
  echo "$first_line" | sed -n 's/.*<!-- ANCHOR: \(.*\) -->.*/\1/p'
}

# Extract PATCH marker name from patch file (line 2)
get_patch_marker() {
  local patch_file="$1"
  local second_line
  second_line=$(sed -n '2p' "$patch_file")
  # Extract content between <!-- PATCH: and -->
  echo "$second_line" | sed -n 's/.*<!-- PATCH:\(.*\) -->.*/\1/p'
}

# Check if a skill file already has our patch marker
is_patched() {
  local skill_file="$1"
  local marker="$2"
  grep -qF "<!-- PATCH:${marker} -->" "$skill_file" 2>/dev/null
}

# Escape special regex characters in anchor for grep
escape_for_grep() {
  echo "$1" | sed 's/[][*.\\/^${}()|+?]/\\&/g'
}

# Apply a patch: inject content after the anchor line
apply_patch() {
  local skill_file="$1"
  local patch_file="$2"
  local anchor="$3"
  local marker="$4"

  [ -f "$skill_file" ] || return 0
  [ -f "$patch_file" ] || return 0

  # Already patched? Skip.
  is_patched "$skill_file" "$marker" && return 0

  local escaped_anchor
  escaped_anchor=$(escape_for_grep "$anchor")

  # Verify anchor exists in skill file
  grep -q "$escaped_anchor" "$skill_file" 2>/dev/null || return 0

  # Build patched file
  local tmpfile
  tmpfile=$(mktemp)
  local injected=false

  while IFS= read -r line || [ -n "$line" ]; do
    printf '%s\n' "$line" >> "$tmpfile"
    if [ "$injected" = false ] && echo "$line" | grep -q "$escaped_anchor"; then
      printf '\n' >> "$tmpfile"
      cat "$patch_file" >> "$tmpfile"
      printf '\n' >> "$tmpfile"
      injected=true
    fi
  done < "$skill_file"

  if [ "$injected" = true ]; then
    cp "$tmpfile" "$skill_file"
  fi
  rm -f "$tmpfile"
}

# --- Main ---

VERSION=$(find_latest_version) || exit 0
SKILLS_DIR="${PLUGINS_CACHE}/${VERSION}/skills"

[ -d "$PATCHES_DIR" ] || exit 0

# Auto-discover and apply all patches
for patch_file in "${PATCHES_DIR}"/*.patch.md; do
  [ -f "$patch_file" ] || continue

  # Skill name = filename without .patch.md
  skill_name=$(basename "$patch_file" .patch.md)
  skill_file="${SKILLS_DIR}/${skill_name}/SKILL.md"

  # Skip if skill doesn't exist
  [ -f "$skill_file" ] || continue

  # Extract anchor and marker from patch file
  anchor=$(get_anchor "$patch_file")
  marker=$(get_patch_marker "$patch_file")

  # Skip if can't parse
  [ -n "$anchor" ] || continue
  [ -n "$marker" ] || continue

  # Apply
  apply_patch "$skill_file" "$patch_file" "$anchor" "$marker"
done

# Output nothing — zero token consumption
exit 0
