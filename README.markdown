# `httpspell`

This is a simple spellchecker that fetches HTML pages and runs them as plain text (converted with [pandoc]()) through [hunspell]().

Before converting, it removes the following nodes as they are not a good target for spellchecking:

* `code`
* `pre`
* Elements with `spellcheck='false'` (this is how HTML5 allows tagging elements as a target for spellchecking)

# Misc

If you produce content with kramdown (e.g. using Jekyll), setting `spellcheck='false'` for an element is a simple as adding this line *after* the paragraph etc.:

```
{: spellcheck="false"}
```
