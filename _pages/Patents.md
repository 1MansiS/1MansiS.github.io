---
layout: page
title: Patents
subtitle: Intellectual property in static analysis and software security.
permalink: /patents/
---

## Granted

{% for patent in site.data.patents.granted %}{% include patent-card.html patent=patent %}{% endfor %}

---

## Pending

{% for patent in site.data.patents.pending %}{% include patent-card.html patent=patent pending=true %}{% endfor %}
