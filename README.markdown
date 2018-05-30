# `httpspell`

This is a spellchecker that recursively fetches HTML pages, converts them to plain text (using [pandoc](http://pandoc.org/)), and spellchecks them with [hunspell](https://hunspell.github.io/). Unknown words will be printed to `stdout`, which makes the tool a good candidate for CI pipelines where you might want to take action when a spelling error is found on a web page.

Words that are not in the dictionary for the given language (inferred from the `lang` attribute of the HTML document's root element) can be added to a personal dictionary, which will mark the word as correctly spelled.

# What is *not* checked

* When spidering a site, `httpspell` will skip all responses with a `content-type` header other than `text/html`.
* Before converting, `httpspell` removes the following nodes from the HTML DOM as they are not a good target for spellchecking:
  - `code`
  - `pre`
  - Elements with `spellcheck='false'` (this is how HTML5 allows tagging elements as a target for spellchecking)

# Misc

If you produce content with kramdown (e.g. using Jekyll), setting `spellcheck='false'` for an element is a simple as adding this line *after* the element (e.g. heading):

```
{: spellcheck="false"}
```
