---
layout: page
title: Open Source Projects
eyebrow: Projects
subtitle: Code I've written, open-sourced, and maintained.
permalink: /projects/
---

{% assign featured = site.projects | where: "featured", true %}
{% assign rest = site.projects | where: "featured", false %}

{% if featured.size > 0 %}
## Featured

{% for p in featured %}{% include project-card.html project=p featured=true %}{% endfor %}
{% endif %}

## All Projects

<div class="proj-grid">
{% for p in rest %}{% include project-card.html project=p %}{% endfor %}
</div>

All repositories on [GitHub →](https://github.com/1MansiS)
