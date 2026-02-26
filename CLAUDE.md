# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# First-time setup only (removes conflicting minima theme files, runs bundle install)
bash setup.sh

# Local development server → http://localhost:4000
bundle exec jekyll serve

# Build only (no server)
bundle exec jekyll build
```

There are no lint or test commands — this is a static Jekyll site.

## Architecture

**Jekyll 4.3, no theme.** The site intentionally omits the minima theme. All styling lives in `assets/css/style.css` (a single flat file with numbered section comments). `assets/main.scss` and `_includes/head.html` / `_includes/header.html` are intentional blank stubs that prevent Jekyll from loading default theme assets — do not delete them.

**Navigation** is driven entirely by `_config.yml` under the `nav:` key (supports `dropdown: true` with `children:`). No HTML edits needed to change the top bar.

**Layouts** (`_layouts/`):
- `default` — base shell with nav, head, footer (actual HTML, not delegating to includes)
- `page` — wraps content in `.pg > .pg-hd + .prose` for standard pages
- `post` — blog post with date/tag metadata and back link
- `ai-note` — AI topic pages with a colored banner driven by `topic:` front matter

**Collections**:
- `_pages/` → permalink `/:path/`, default layout `page`
- `_pages/ai/` → override layout `ai-note` (set via `_config.yml` defaults)
- `_posts/` → standard Jekyll posts, default layout `post`

**AI Notes pattern** — notes are raw HTML `<div>` blocks inside markdown files in `_pages/ai/`:
```html
<div class="note n-{topic}">
  <div class="note-meta"><span class="n-tag t-{topic}">Tag</span></div>
  <h3>Title</h3>
  <p>Content</p>
</div>
```
Topic values and their accent colors: `foundations` (blue), `llm` (purple), `rag` (green), `secai` (red), `reading` (amber). Add `note-wip` class for in-progress notes. Reading log entries use `read-row` divs with `read-pill` status badges (`rp-done`, `rp-reading`, `rp-queue`) instead of the `note` pattern.

**CSS tokens** are defined in `:root` at the top of `assets/css/style.css`. Color palette: `--gold` / `--gold2` as primary accent; five topic-specific color sets (`--blue`, `--purple`, `--green`, `--red`, `--amber`) each with `-bg` and `-bd` variants for backgrounds and borders.

**`_site/`** is the build output directory — do not edit files there directly.
