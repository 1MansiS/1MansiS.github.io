---
layout: ai-note
title: Reading Log
subtitle: Papers, books, and courses I've read — tracked with status and quick reactions.
topic: reading
icon: 📚
permalink: /ai/reading-log/
---

{% assign grouped = site.notes | where: "topic", "reading" | group_by: "section" %}
{% for grp in grouped %}{% include read-section.html group=grp %}{% endfor %}
