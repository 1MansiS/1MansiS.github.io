---
layout: page
title: Talks & Conferences
subtitle: DEF CON, JavaOne, SecTor, JavaZone, NorthSec and more — on cryptography and security engineering.
permalink: /talks/
---

## Conference Talks

{% for talk in site.data.talks.conference %}{% include talk-card.html talk=talk %}{% endfor %}

---

## Vulnerability Research & Evangelism

{% for item in site.data.talks.research %}{% include talk-card.html talk=item %}{% endfor %}

---

Interested in having me speak? [Get in touch →](/contact/)
