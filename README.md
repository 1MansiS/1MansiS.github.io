# 1MansiS.github.io — Site Reference

Everything you need to extend and maintain this site.

---

## Quick Start

```bash
bash setup.sh              # first time only — removes old theme conflicts
bundle exec jekyll serve   # http://localhost:4000
bundle exec jekyll build   # build only, no server
```

---

## Architecture at a Glance

```
_config.yml          ← site settings, nav bar, author info
_data/               ← structured content (talks, patents)
_notes/              ← AI notes collection (one file per note)
_posts/              ← blog posts
_projects/           ← OSS projects collection (one file per project)
_pages/              ← all navigable pages
  ai/                ← AI Notes sub-pages
_layouts/            ← page shells (default, page, post, home, ai-note, blog, contact)
_includes/           ← reusable HTML components
assets/css/style.css ← all styling, single file
```

The site has **no theme**. All HTML lives in `_layouts/` and `_includes/`. All styling is in `assets/css/style.css`. Markdown files contain only front matter and Liquid calls — no raw HTML.

---

## Adding AI Notes

Notes live in `_notes/` as individual markdown files. They render automatically on the matching topic page — no other file needs touching.

**Create `_notes/your-note-slug.md`:**

```yaml
---
topic: secai           # foundations | llm | rag | secai | reading
section: "Podcasts"    # free-form — becomes a section header on the page
tag: Podcast           # small colored pill label (omit if wip: true)
title: "Note Title"
wip: true              # optional — dashed border + "in progress" label
---
Your note content. Full markdown: **bold**, `code`, bullet lists, all work.

- Point one
- Point two
```

**Topic → page mapping:**

| `topic:` value | Renders on |
|---|---|
| `foundations` | `/ai/foundations/` |
| `llm` | `/ai/llm-systems/` |
| `rag` | `/ai/rag-retrieval/` |
| `secai` | `/ai/security-x-ai/` |
| `reading` | `/ai/reading-log/` (different format — see below) |

**Sections** are free-form strings. Notes with the same `section:` value are grouped under one header. New sections appear automatically — no config change needed. Sections appear in the order their first note is encountered (alphabetical by filename), so prefix filenames with numbers to control order: `secai-01-...`, `secai-02-...`.

**WIP notes** — add `wip: true` and omit `tag:`. The card renders with a dashed border and "in progress" badge.

---

## Adding Reading Log Entries

Reading log entries are also in `_notes/`, with `topic: reading` and a different front matter shape:

**Create `_notes/reading-your-title.md`:**

```yaml
---
topic: reading
section: "Papers"      # Papers | Books | Courses | Reference — or anything new
title: "Paper or Book Title"
url: "https://..."     # optional — omit for books without a public URL
author: "Author · Publisher · Year · one-line description"
status: done           # done | reading | queue
---
```

Leave the body empty — the reading log renders title, author, and a status pill. No note content needed.

**Status pill values:**

| `status:` | Pill |
|---|---|
| `done` | Read (green) |
| `reading` | Reading (blue) |
| `queue` | To Read (grey) |

---

## Adding Projects

Projects live in `_projects/` as individual markdown files. They render on `/projects/` automatically.

**Create `_projects/your-project.md`:**

```yaml
---
title: "Project Name"
github: "https://github.com/1MansiS/repo"   # omit if not yet public
category: Tool          # Tool | Blog Series | Talk Companion | Research
tags: [Tag1, Tag2]
featured: false         # true = large featured card at top
status: active          # active | coming-soon | archived
---
One or two sentences describing what it does and why it matters.
```

- `featured: true` renders a large card above the grid with a status badge.
- `featured: false` renders in the two-column grid using the `.acard` style.
- Leave `github:` blank (or omit it) for projects not yet public.

---

## Adding Blog Posts

Posts live in `_posts/` following standard Jekyll naming: `YYYY-MM-DD-title.md`.

**Create `_posts/2026-02-24-your-post-title.md`:**

```yaml
---
layout: post
title: "Post Title"
date: 2026-02-24
tags: [Cryptography, Java]
---
Post content in markdown. Full prose styling applied automatically.
```

Posts appear on `/blog/` and the homepage "Latest Writing" grid (most recent 6) automatically.

---

## Adding Talks

Talks are in `_data/talks.yml`. The `/talks/` page renders from this file — no HTML to edit.

**Add a conference talk** under `conference:`:

```yaml
conference:
  - year: "2026"
    title: "Your Talk Title"
    events:
      - label: "Conference Name — Watch Recording ↗"
        url: "https://youtube.com/..."
      - label: "Another Conference"
        url: "https://..."
```

**Add a research/evangelism item** under `research:`:

```yaml
research:
  - title: "Topic You Spoke About"
    label: "Panel Discussion on LinkedIn ↗"
    url: "https://linkedin.com/..."
```

---

## Adding Patents

Patents are in `_data/patents.yml`. The `/patents/` page renders from this file.

**Add a granted patent** under `granted:`:

```yaml
granted:
  - pill: "Granted · Mon YYYY"
    title: "Full Patent Title"
    number: "US 12,345,678"
    url: "https://patents.justia.com/patent/12345678"
```

**Add a pending application** under `pending:`:

```yaml
pending:
  - title: "Full Patent Title"
    application: "20XXXXXXXX"
    url: "https://patents.justia.com/patent/20XXXXXXXX"
```

---

## Updating Bio & Contact Info

**Bio paragraph** (homepage hero) — edit `index.md`. The entire file body is the bio.

**Author details** (used by contact page, footer, feed) — edit `_config.yml`:

```yaml
author:
  name: Mansi Sheth
  email: mansi.sheth@gmail.com
  twitter: 1MansiS
  github: 1MansiS
  linkedin: shethmansi
```

The contact page cards are auto-generated from these values — no HTML to edit.

---

## Updating the Nav Bar

Edit `_config.yml` under `nav:`. Supports flat links and dropdowns with children:

```yaml
nav:
  - label: About
    url: /
  - label: AI Notes
    dropdown: true
    children:
      - label: "🧱 Foundations"
        url: /ai/foundations/
  - label: Resume
    url: /assets/MansiSheth.pdf
    new_tab: true
```

---

## Adding a New AI Topic Page

1. Create `_pages/ai/your-topic.md` with this front matter:

```yaml
---
layout: ai-note
title: Your Topic
subtitle: One-line description.
topic: yourtopic      # pick a new short slug
icon: 🆕
permalink: /ai/your-topic/
---

{% assign grouped = site.notes | where: "topic", "yourtopic" | group_by: "section" %}
{% for grp in grouped %}{% include note-section.html group=grp %}{% endfor %}
```

2. Add CSS tokens for the new topic color in `assets/css/style.css` (Section 1 — Tokens):

```css
--mytopic: #5A7A3A;  --mytopic-bg: #F0F5EC;  --mytopic-bd: #B8D4A0;
```

3. Add the banner, note, and tag styles in Section 11 (AI NOTES):

```css
.ai-banner.b-yourtopic { background: var(--mytopic-bg); border-color: var(--mytopic); }
.note.n-yourtopic      { border-left-color: var(--mytopic); }
.n-tag.t-yourtopic     { background: var(--mytopic-bg); color: var(--mytopic); border: 1px solid var(--mytopic-bd); }
```

4. Add the new tab to the sub-nav in `_layouts/ai-note.html`.

5. Add the dropdown entry in `_config.yml` under the AI Notes nav item.

---

## Reading Log vs Topic Notes — Rule of Thumb

These two overlap and that's intentional. A single source often generates entries in both places.

**Reading Log** answers: *"What have I consumed, and have I read it yet?"*
It's a bibliographic record — the artifact (paper, book, podcast, tutorial, course) plus a status badge. The entry itself has no opinions or takeaways. Think of it as your personal library catalog.

**Topic notes** answer: *"What do I actually know about X?"*
They're your synthesis — mental models, key insights, things worth remembering. A note should be useful to future-you without having to go back to the source.

### The two specific examples

| Scenario | Reading Log | Topic Note |
|---|---|---|
| Anthropic skills tutorial | ✅ section: "Tutorials", status: done | ✅ `topic: llm`, section: "Tool Use & APIs" — your key takeaways |
| Podcast on prompt injection | ✅ section: "Podcasts", status: done | ✅ `topic: secai`, section: "Attacking LLMs" — insights worth keeping |

### Decision table

| Source type | Reading Log? | Topic note? |
|---|---|---|
| Research paper | Always — with URL + authors | If you have genuine takeaways |
| Book | Always | If a chapter teaches a concept worth noting |
| Podcast / interview | Yes — section: "Podcasts" | If it changed how you think about something |
| Tutorial / docs (e.g. Anthropic, OpenAI) | Yes — section: "Tutorials" | Yes — what you learned, not a summary |
| Blog post | Optional (only if you'd want to find it again) | If it contains a model or insight worth keeping |
| Conference talk / video | Yes — section: "Talks & Videos" | If it introduces a concept or framework |
| Course | Yes (track progress with `status: reading`) | Yes — per-concept notes as you go |

### What goes in which topic

| Content | Topic |
|---|---|
| How transformers work, attention, tokenization, training phases | `foundations` |
| Context windows, agents, tool use, inference, prompting patterns | `llm` |
| Chunking, embedding, vector search, retrieval evaluation | `rag` |
| Attacks on LLMs, jailbreaks, prompt injection, supply chain, defenses | `secai` |
| Any paper, book, podcast, tutorial, course you consumed | `reading` |

**When in doubt:** if you're recording *that something exists*, it's a reading log entry. If you're recording *what it taught you*, it's a topic note. If it's substantial enough, do both.

---

## Layouts Reference

| Layout | Used by | What it does |
|---|---|---|
| `default` | base for all others | nav, footer, `<main>` wrapper |
| `page` | most `_pages/` | `.pg > .pg-hd + .prose` with eyebrow/title/subtitle |
| `post` | `_posts/` | date, tags, back link, prose body |
| `home` | `index.md` | hero grid + bio + latest posts |
| `ai-note` | `_pages/ai/` | sub-nav tabs + colored banner |
| `blog` | `_pages/blog.md` | posts list, auto-rendered |
| `contact` | `_pages/contact.md` | contact grid, reads from `site.author` |

---

## Includes Reference

| Include | Parameters | Used by |
|---|---|---|
| `note.html` | `note=` (a `_notes` doc) | `note-section.html` |
| `note-section.html` | `group=` (a Liquid group object) | AI topic pages |
| `read-row.html` | `entry=` (a `_notes` doc with `topic: reading`) | `read-section.html` |
| `read-section.html` | `group=` (a Liquid group object) | `reading-log.md` |
| `talk-card.html` | `talk=` (item from `site.data.talks`) | `talks.md` |
| `patent-card.html` | `patent=`, `pending=true/false` | `patents.md` |
| `project-card.html` | `project=` (a `_projects` doc), `featured=true/false` | `projects.md` |

---

## CSS Quick Reference

All tokens are in `:root` at the top of `assets/css/style.css`.

**Primary accent:** `--gold` / `--gold2`

**Topic colors** (each has `-bg` and `-bd` variants for backgrounds/borders):

| Token | Used for |
|---|---|
| `--blue` | Foundations notes |
| `--purple` | LLM Systems notes |
| `--green` | RAG & Retrieval notes |
| `--red` | Security × AI notes |
| `--amber` | Reading Log notes |

**Section numbers** in `style.css` for quick navigation:
`1` Tokens · `2` Reset · `3` Nav · `4` Page Wrapper · `5` Prose · `6` Home · `7` Blog List · `8` Post · `9` Achievement Cards · `10` Contact · `11` AI Notes · `12` AI Subnav · `13` Projects · `14` Footer · `15` Responsive
