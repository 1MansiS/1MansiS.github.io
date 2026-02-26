---
topic: reading
section: "Podcasts"
title: "AI - Pen Testing"
author: "How AI Pen Testing Actually Works and Where It Breaks"
link: "https://podcasts.apple.com/us/podcast/how-ai-pen-testing-actually-works-and-where-it-breaks/id1680660068?i=1000750360214"
status: done
date: 2026-02-26
---

- Mostly low hanging fruits — routine, boring, mundane tasks of pen testing: login, maintain an authenticated session
- **Where it's not helping:** subtle issues that require chaining a bunch of things together and providing rich context
- Can scale and speed up compared to manual testing

**Scope control** (how to stop it from going off into prod):
- Domain blocks, network-level restrictions, URL blocks
- Agent that checks each command before execution
- Don't show motivation or thinking behind a command — just show the command to execute ("deaf card") — because LLMs are great at coming up with convincing arguments, so more context = LLM convincing itself it's fine to proceed

**Cost considerations:**
- Older model training is getting drastically cheaper — if VC money dries up, teams may fall back to existing/older models
- As scale increases, cost increases — find sensible non-AI ways to crawl/gather data and only feed relevant pieces to agents. You don't need AI to do everything.

**Mistakes seen:**
- *Lows:* Smaller issues made to look like a huge deal (e.g., security headers missing)
- *Highs:* Creative findings, such as passing `/etc/passwd` as an image

**What AI is good at finding:**
- Great at verifying what it has done
- XSS, SQLi, arbitrary file reads
- Can generate a Python script to verify findings

**What AI is not good at:**
- Authorization issues
- Business logic flaws — "I wasn't supposed to do that right there"
- This is where the biggest research/engineering effort is being focused
