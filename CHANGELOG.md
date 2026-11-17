# Changelog

All notable changes to LLM Wiki will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `scripts/build-index.sh`: regenerates `.llm-wiki/index.md` from page frontmatter and stores the index hash, so the workflows' "programmatic" index step has a script
- `.gitattributes` keeping LF line endings, so Windows clones with `core.autocrlf=true` get working bash scripts and LF templates

### Fixed

- `find-broken-links.sh` and `find-orphans.sh` read only the last `[[link]]` on each line, missing broken links and reporting linked pages as orphans
- `find-orphans.sh` counted links from `index.md`, which links to every page, so no orphan was ever found where the symlink exists
- `check-stale.sh` hashed pages in filesystem order and included body `---` lines; it now hashes the frontmatter only, in sorted order
- `init-wiki.sh` left a stale copy of the index as `wiki/index.md` where symlinks are unavailable (Git Bash on Windows); it now creates a real symlink or nothing
- `setup-project.sh` added `CLAUDE.md` to `.gitignore` and put the wiki rules above the project's own; it now appends them and ignores only the wiki's `cache/` and `graph.html`
- The ingest workflow said `check-stale.sh` stores the index hash; it only prints it

## [0.1.0] — 2026-05-03

### Added

- Initial release of LLM Wiki skill for Claude Code
- Two-phase source ingestion (`/wiki-ingest`) with SHA-256 idempotency
- Index-first knowledge retrieval (`/wiki-query`) for O(1) lookup
- Health check system (`/wiki-lint`) with quick (bash) and full (LLM) modes
- Answer-to-synthesis persistence (`/wiki-save`) for compounding knowledge
- D3.js knowledge graph visualization (`/wiki-graph`)
- Review queue processing (`/wiki-review`) for contradiction/quality management
- Wiki dashboard (`/wiki`)
- Bilingual support (en/zh/bilingual) with CJK auto-detection
- Session lifecycle hooks (start/stop) with hot-cache for context continuity
- Page templates for concept, article, person, and synthesis types
- Project setup script (`setup-project.sh`) with optional hooks configuration
- Wiki initialization script (`init-wiki.sh`)
- Global installation script (`install.sh`)
- Quickstart script (`quickstart.sh`) with demo content
- Uninstall script (`uninstall.sh`)
- Demo source files (Greek mythology)
- CI pipeline (ShellCheck + markdownlint + integration tests)
- Local CI runner (`scripts/ci-local.sh`)
- Community files (CoC, Contributing, Security, Support, PR/Issue templates)

### Fixed

- CI failures in initial workflow configuration
- Portability issues for non-Linux environments
