#!/usr/bin/env bash
# Superpowers Patcher v3 (awk-based, fast)
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
#
# v3: Rewrote parse_blocks + apply_blocks as single awk pass per file pair.
#     ~10x faster than v2's bash while-read loops.

set -euo pipefail

PATCHES_DIR="$HOME/.claude/patches"
PLUGINS_CACHE="$HOME/.claude/plugins/cache/claude-plugins-official/superpowers"

find_latest_version() {
  [ -d "$PLUGINS_CACHE" ] || return 1
  ls -1 "$PLUGINS_CACHE" | sort -V | tail -1
}

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

# Apply patch blocks to skill file using awk (single pass per file pair).
# Reads patch_file first to parse anchors/content, then processes skill_file.
apply_patch() {
  local skill_file="$1"
  local patch_file="$2"
  local tmp_out="${skill_file}.tmp"

  awk '
  # Phase 1: read patch file (first file argument)
  NR == FNR {
    if (index($0, "<!-- ANCHOR:") > 0 && index($0, "-->") > 0) {
      s = $0
      sub(/.*<!-- ANCHOR: /, "", s)
      sub(/ -->.*/, "", s)
      nb++
      anchor[nb] = s
      collecting = 0
      if (substr(s, 1, 1) == "#") {
        mode[nb] = "replace"
        lvl = 0
        while (substr(s, lvl + 1, 1) == "#") lvl++
        level[nb] = lvl
      } else {
        mode[nb] = "insert"
        level[nb] = 0
      }
    } else if (index($0, "<!-- PATCH:") > 0 && !collecting && nb > 0) {
      collecting = 1
      content[nb] = "<!-- ANCHOR: " anchor[nb] " -->\n" $0
    } else if (collecting && nb > 0) {
      content[nb] = content[nb] "\n" $0
    }
    next
  }

  # Phase 2: process skill file (second file argument)
  {
    if (skip) {
      if ($0 ~ /^#+[[:space:]]/) {
        match($0, /^#+/)
        if (RLENGTH <= skip_lvl) {
          skip = 0
          # fall through to anchor matching below
        } else {
          next
        }
      } else {
        next
      }
    }

    matched = 0
    for (i = 1; i <= nb; i++) {
      if (index($0, anchor[i]) > 0) {
        print $0
        print ""
        print content[i]
        if (mode[i] == "replace") {
          skip = 1
          skip_lvl = level[i]
        }
        matched = 1
        break
      }
    }
    if (!matched) print $0
  }
  ' "$patch_file" "$skill_file" > "$tmp_out" && mv "$tmp_out" "$skill_file"
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

  ensure_original "$skill_file" || continue
  apply_patch "$skill_file" "$patch_file"
done

exit 0
