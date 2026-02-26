---
layout: ai-note
title: Foundations
subtitle: Core ML concepts, transformers, training — the building blocks before everything else.
topic: foundations
icon: 🧱
permalink: /ai/foundations/
---

{% assign grouped = site.notes | where: "topic", "foundations" | group_by: "section" %}
{% for grp in grouped %}{% include note-section.html group=grp %}{% endfor %}
