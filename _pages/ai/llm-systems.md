---
layout: ai-note
title: LLM Systems
subtitle: How LLMs are deployed and orchestrated — agents, tool calling, context windows, inference.
topic: llm
icon: 🤖
permalink: /ai/llm-systems/
---

{% assign grouped = site.notes | where: "topic", "llm" | group_by: "section" %}
{% for grp in grouped %}{% include note-section.html group=grp %}{% endfor %}
