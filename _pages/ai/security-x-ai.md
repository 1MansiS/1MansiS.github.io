---
layout: ai-note
title: Security × AI
subtitle: Where my two worlds collide — attacking AI systems, defending with AI, and building secure LLM applications.
topic: secai
icon: 🔐
permalink: /ai/security-x-ai/
---

{% assign grouped = site.notes | where: "topic", "secai" | group_by: "section" %}
{% for grp in grouped %}{% include note-section.html group=grp %}{% endfor %}
