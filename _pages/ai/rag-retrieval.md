---
layout: ai-note
title: RAG & Retrieval
subtitle: Retrieval-Augmented Generation — embedding, chunking, indexing, and hybrid search.
topic: rag
icon: 🔍
permalink: /ai/rag-retrieval/
---

{% assign grouped = site.notes | where: "topic", "rag" | group_by: "section" %}
{% for grp in grouped %}{% include note-section.html group=grp %}{% endfor %}
