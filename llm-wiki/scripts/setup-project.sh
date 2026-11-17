#!/bin/bash
# setup-project.sh — Set up LLM Wiki in a project directory
# Usage: setup-project.sh [wiki-path] [--with-hooks]
#   wiki-path     Path to create wiki at (default: ./wiki)
#   --with-hooks  Also configure SessionStart hook in settings
# Exit: 0 on success, 1 on error

set -euo pipefail

WITH_HOOKS=false
WIKI_PATH=""

for arg in "$@"; do
    case "$arg" in
        --help|-h)
            echo "Usage: setup-project.sh [wiki-path] [--with-hooks]"
            echo ""
            echo "Set up LLM Wiki in your project:"
            echo "  1. Bootstraps the wiki directory with init-wiki.sh"
            echo "  2. Creates CLAUDE.md with wiki instructions, or appends them to an existing one"
            echo "  3. Creates .raw/ directory for source documents"
            echo "  4. Adds the wiki's cache/ and graph.html to an existing .gitignore"
            echo ""
            echo "Options:"
            echo "  wiki-path      Path for the wiki (default: ./wiki)"
            echo "  --with-hooks   Configure SessionStart hook in .claude/settings.local.json"
            echo "  --help, -h     Show this help"
            exit 0 ;;
        --with-hooks) WITH_HOOKS=true ;;
        *)
            if [ -z "$WIKI_PATH" ]; then
                WIKI_PATH="$arg"
            else
                echo "Unknown option: $arg (use --help for usage)" >&2; exit 1
            fi ;;
    esac
done

# Default wiki path
WIKI_PATH="${WIKI_PATH:-./wiki}"

# Resolve skill directory
SKILL_DIR="$HOME/.claude/skills/llm-wiki"
if [ ! -d "$SKILL_DIR" ]; then
    echo "ERROR: LLM Wiki skill not installed." >&2
    echo "Run install.sh first: cd llm-wiki && ./install.sh" >&2
    exit 1
fi

echo "=== LLM Wiki Project Setup ==="
echo ""

# Step 1: Initialize wiki directory
echo "1. Initializing wiki at $WIKI_PATH..."
if [ -d "$WIKI_PATH/.llm-wiki" ]; then
    echo "   ✓ Wiki already exists at $WIKI_PATH"
else
    "$SKILL_DIR/scripts/init-wiki.sh" "$WIKI_PATH"
    echo "   ✓ Wiki initialized"
fi

# Step 2: Create .raw/ directory
if [ ! -d "./.raw" ]; then
    mkdir -p ./.raw
    echo "   ✓ Created ./.raw/ for source documents"
fi

# Step 3: Create/update CLAUDE.md
echo ""
echo "2. Setting up CLAUDE.md..."

CLAUDE_MD="./CLAUDE.md"
WIKI_MD="$SKILL_DIR/WIKI.md"

if [ -f "$CLAUDE_MD" ]; then
    # If CLAUDE.md exists, check if it already has wiki instructions
    if grep -q "LLM Wiki" "$CLAUDE_MD" 2>/dev/null; then
        echo "   ✓ CLAUDE.md already has wiki instructions"
    else
        # Append wiki instructions to existing CLAUDE.md, so the project's own
        # rules stay first and keep precedence over the generic wiki rules
        echo "   → CLAUDE.md exists, appending wiki instructions..."
        {
            echo ""
            echo "---"
            echo ""
            echo "<!-- LLM Wiki instructions added by setup-project.sh -->"
            echo ""
            cat "$WIKI_MD"
        } >> "$CLAUDE_MD"
        echo "   ✓ Wiki instructions appended to CLAUDE.md"
    fi
else
    cp "$WIKI_MD" "$CLAUDE_MD"
    echo "   ✓ Created CLAUDE.md with wiki instructions"
fi

# Step 4: Optionally configure hooks
if [ "$WITH_HOOKS" = true ]; then
    echo ""
    echo "3. Configuring SessionStart hook..."

    SETTINGS_FILE=".claude/settings.local.json"

    if [ -f "$SETTINGS_FILE" ]; then
        # Update existing settings with jq
        if command -v jq >/dev/null 2>&1; then
            jq --arg cmd "$SKILL_DIR/hooks/session-start.sh" \
               '.hooks.SessionStart = [{"matcher": "", "command": $cmd}]' \
               "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && \
            mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE" && \
            echo "   ✓ SessionStart hook configured in $SETTINGS_FILE"
        else
            echo "   ⚠ jq not found. Install jq or add the hook manually:"
            echo "     See: https://claude.com/claude-code for hook configuration"
        fi
    else
        # Create new settings file
        mkdir -p .claude
        cat > "$SETTINGS_FILE" << SETEOF
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "command": "$SKILL_DIR/hooks/session-start.sh"
      }
    ]
  }
}
SETEOF
        echo "   ✓ Created $SETTINGS_FILE with SessionStart hook"
    fi
else
    echo ""
    echo "3. (Optional) Configure SessionStart hook for richer startup context:"
    echo "   Re-run with --with-hooks, or add to .claude/settings.local.json:"
    echo ""
    echo '   {'
    echo '     "hooks": {'
    echo '       "SessionStart": [{'
    echo "         \"command\": \"$SKILL_DIR/hooks/session-start.sh\""
    echo '       }]'
    echo '     }'
    echo '   }'
fi

# Step 5: Ignore the wiki's volatile files (never CLAUDE.md: it holds the
# project's own instructions and must stay tracked)
GITIGNORE="./.gitignore"
if [ -f "$GITIGNORE" ]; then
    WIKI_REL="${WIKI_PATH#./}"
    for pattern in "$WIKI_REL/.llm-wiki/cache/" "$WIKI_REL/.llm-wiki/graph.html"; do
        if ! grep -qxF "$pattern" "$GITIGNORE" 2>/dev/null; then
            if ! grep -q "^# LLM Wiki" "$GITIGNORE" 2>/dev/null; then
                printf '\n# LLM Wiki: hashes, hot-cache and the generated graph page\n' >> "$GITIGNORE"
            fi
            echo "$pattern" >> "$GITIGNORE"
            echo "   ✓ Added $pattern to .gitignore"
        fi
    done
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Wiki is ready at: $WIKI_PATH"
echo "Drop source documents in ./.raw/ then use:"
echo "  /wiki-ingest .raw/your-file.md"
echo ""
echo "Ask questions naturally — Claude will check the wiki first!"
