---
layout: page
title: Categories
icon: fas fa-stream
order: 1
---

<div class="category-accordion-list">
  {% assign category_posts = site.categories['개발'] %}
  <details class="category-accordion">
    <summary><span class="category-accordion-title"><span class="category-chevron">▸</span>개발</span><span class="category-count">{{ category_posts | size }}</span></summary>
    {% include category-tags.html category_name='개발' topic_url='/topics/development/' %}
  </details>

  {% assign category_posts = site.categories['CTF/Wargame'] %}
  <details class="category-accordion">
    <summary><span class="category-accordion-title"><span class="category-chevron">▸</span>CTF/Wargame</span><span class="category-count">{{ category_posts | size }}</span></summary>
    {% include category-tags.html category_name='CTF/Wargame' topic_url='/topics/ctf-wargame/' %}
  </details>

  {% assign category_posts = site.categories['Bug Bounty'] %}
  <details class="category-accordion">
    <summary><span class="category-accordion-title"><span class="category-chevron">▸</span>Bug Bounty</span><span class="category-count">{{ category_posts | size }}</span></summary>
    {% include category-tags.html category_name='Bug Bounty' topic_url='/topics/bug-bounty/' %}
  </details>

  {% assign category_posts = site.categories['블로그/기술문서'] %}
  <details class="category-accordion">
    <summary><span class="category-accordion-title"><span class="category-chevron">▸</span>블로그/기술문서</span><span class="category-count">{{ category_posts | size }}</span></summary>
    {% include category-tags.html category_name='블로그/기술문서' topic_url='/topics/technical-writing/' %}
  </details>

  {% assign category_posts = site.categories['논문/컨퍼런스'] %}
  <details class="category-accordion">
    <summary><span class="category-accordion-title"><span class="category-chevron">▸</span>논문/컨퍼런스</span><span class="category-count">{{ category_posts | size }}</span></summary>
    {% include category-tags.html category_name='논문/컨퍼런스' topic_url='/topics/papers-conferences/' %}
  </details>

  {% assign category_posts = site.categories['공모전/자격증'] %}
  <details class="category-accordion">
    <summary><span class="category-accordion-title"><span class="category-chevron">▸</span>공모전/자격증</span><span class="category-count">{{ category_posts | size }}</span></summary>
    {% include category-tags.html category_name='공모전/자격증' topic_url='/topics/competitions-certifications/' %}
  </details>
</div>
