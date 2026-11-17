#!/bin/bash
# _utils.sh — Shared utility functions for LLM Wiki scripts
# Source this file from other scripts to avoid duplicating common functions.
#
# Usage: source "$(dirname "${BASH_SOURCE[0]}")/_utils.sh"

# find_wiki_root — Locate the wiki directory
# Checks LLM_WIKI_ROOT env var first, then ./wiki as fallback.
# Returns the wiki root path, or empty string if not found.
find_wiki_root() {
    if [ -n "${LLM_WIKI_ROOT:-}" ] && [ -d "$LLM_WIKI_ROOT/.llm-wiki" ]; then
        echo "$LLM_WIKI_ROOT"
    elif [ -d "./wiki/.llm-wiki" ]; then
        echo "./wiki"
    else
        echo ""
    fi
}
# list_pages — Print every wiki page file (NUL-separated), sorted bytewise so
# results do not depend on filesystem order. Skips index.md and .llm-wiki/.
list_pages() {
    find "$1" -maxdepth 1 -name "*.md" ! -name "index.md" -print0 2>/dev/null | LC_ALL=C sort -z
}

# extract_links — Print the target of every [[wikilink]] in a file, one per
# line, including several links on one line. Drops |display text and #anchors.
extract_links() {
    grep -o '\[\[[^]]*\]\]' "$1" 2>/dev/null | sed -e 's/^\[\[//' -e 's/\]\]$//' -e 's/|.*//' -e 's/#.*//' || true
}

# frontmatter — Print a page's leading YAML frontmatter block, both --- lines
# included. Later --- lines in the body (horizontal rules) are not included.
frontmatter() {
    awk 'NR == 1 && /^---$/ { f = 1; print; next } f { print; if (/^---$/) exit }' "$1"
}

# frontmatter_hash — SHA-256 of all pages' frontmatter in sorted file order.
# check-stale.sh compares against it; build-index.sh stores it.
frontmatter_hash() {
    local file
    list_pages "$1" | while IFS= read -r -d '' file; do frontmatter "$file"; done | sha256sum | cut -d' ' -f1
}
