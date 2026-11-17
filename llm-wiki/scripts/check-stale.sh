#!/bin/bash
# check-stale.sh — Check if the wiki index is stale
# Usage: check-stale.sh <wiki_root>
# Compares stored index hash against live hash of all page frontmatter
# Exit: 0 = fresh, 1 = stale, 2 = no stored hash
# Writes details to stdout

set -euo pipefail

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    echo "Usage: check-stale.sh [wiki_root]"
    echo "Check if the wiki index is stale by comparing stored vs live frontmatter hash."
    echo "  wiki_root   Wiki directory (default: ./wiki)"
    echo "Exit: 0 = fresh, 1 = stale, 2 = no stored hash"
    exit 0
fi

WIKI_ROOT="${1:-./wiki}"
INDEX_HASH_FILE="$WIKI_ROOT/.llm-wiki/cache/index-hash.txt"

if [ ! -d "$WIKI_ROOT" ]; then
    echo "ERROR: Wiki root '$WIKI_ROOT' does not exist" >&2
    exit 1
fi

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/_utils.sh"

# Live hash: all pages' frontmatter blocks in sorted file order (excluding
# .llm-wiki/ and index.md), so the result is the same on every filesystem
LIVE_HASH=$(frontmatter_hash "$WIKI_ROOT")


if [ ! -f "$INDEX_HASH_FILE" ]; then
    echo "STALE: No stored index hash found."
    echo "Current live hash: $LIVE_HASH"
    echo "Store it with: echo '$LIVE_HASH' > $INDEX_HASH_FILE"
    exit 2
fi

STORED_HASH=$(cat "$INDEX_HASH_FILE")

if [ "$LIVE_HASH" = "$STORED_HASH" ]; then
    echo "FRESH: Index is up to date."
    echo "Hash: $LIVE_HASH"
    exit 0
else
    echo "STALE: Index is out of date."
    echo "Stored hash: $STORED_HASH"
    echo "Live hash:   $LIVE_HASH"
    exit 1
fi
