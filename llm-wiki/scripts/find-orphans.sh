#!/bin/bash
# find-orphans.sh — Find wiki pages with zero incoming [[wikilinks]]
# Usage: find-orphans.sh <wiki_root>
# Output: one line per orphan page
# Exit: 0 on success (even if orphans found), 1 on error

set -euo pipefail

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    echo "Usage: find-orphans.sh [wiki_root]"
    echo "Find wiki pages with zero incoming [[wikilinks]]."
    echo "  wiki_root   Wiki directory (default: ./wiki)"
    exit 0
fi

WIKI_ROOT="${1:-./wiki}"

if [ ! -d "$WIKI_ROOT" ]; then
    echo "ERROR: Wiki root '$WIKI_ROOT' does not exist" >&2
    exit 1
fi

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/_utils.sh"

# Collect all page slugs (filenames without .md) in the wiki root
SLUGS=$(list_pages "$WIKI_ROOT" | xargs -0 -r -n1 basename -s .md)

# Collect all wikilink targets across all pages. index.md is skipped: it links
# to every page, so counting it would hide every orphan.
ALL_LINKS=$(list_pages "$WIKI_ROOT" | while IFS= read -r -d '' f; do extract_links "$f"; done | sort -u)

# For each slug, check if it appears as a link target
ORPHANS_FOUND=0
while IFS= read -r slug; do
    [ -z "$slug" ] && continue
    if ! echo "$ALL_LINKS" | grep -qFx "$slug"; then
        echo "ORPHAN: $slug"
        ORPHANS_FOUND=1
    fi
done <<< "$SLUGS"

if [ "$ORPHANS_FOUND" -eq 0 ]; then
    echo "OK: No orphan pages found."
fi
