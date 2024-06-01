# `httpspell`

This is a spellchecker that recursively fetches HTML pages, converts them to plain text (using [pandoc](http://pandoc.org/)), and spellchecks them with [hunspell](https://hunspell.github.io/). Unknown words will be printed to `stdout`, which makes the tool a good candidate for CI pipelines where you might want to take action when a spelling error is found on a web page.

Words that are not in the dictionary for the given language (inferred from the `lang` attribute of the HTML document's root element) can be added to a personal dictionary, which will mark the word as correctly spelled.

# Usage

* The following command will retrieve the HTML document at https://example.com, spellcheck it, and not print anything because there are no errors:

  ```bash
  $ httpspell https://example.com
  ```

  The exit code is `0`.

* The following command will spellcheck the README of this project as rendered by GitHub, and print a list of unknown words. Note that we set the language to `en_US` because GitHub declares 'en' as document language, but the installed dictionaries usually refer the a specific language variant like `en_US`:

  ```bash
  $ httpspell https://github.com/suhlig/httpspell/blob/master/README.markdown --language en_US
  suhlig
  Permalink
  httpspell
  sloc
  pandoc
  hunspell
  ...
  ```

  The exit code is `1`.

# What is *not* checked

* When spidering a site, `httpspell` will skip all responses with a `content-type` header other than `text/html` (unless pointing it to file, in which case it accepts anything).
* Before converting, `httpspell` removes the following nodes from the HTML DOM as they are not a good target for spellchecking:
  - `code`
  - `pre`
  - Elements with `spellcheck='false'` (this is how HTML5 allows tagging elements as a being target for spellchecking or not)

# Misc

If you produce content with kramdown (e.g. using Jekyll), an [Inline Attribute List](https://kramdown.gettalong.org/syntax.html#inline-attribute-lists) can be used to set `spellcheck='false'` for an element by adding this line *after* the element (e.g. heading):

```
{: spellcheck="false"}
```

# Dictionaries

Hunspell uses the system dictionary paths; on the Mac this is `~/Library/Spelling/`. Get some dictionaries as explained in the [hunspell](https://github.com/hunspell/hunspell) project:

```command
$ wget -O ~/Library/Spelling/en_US.aff https://cgit.freedesktop.org/libreoffice/dictionaries/plain/en/en_US.aff
$ wget -O ~/Library/Spelling/en_US.dic https://cgit.freedesktop.org/libreoffice/dictionaries/plain/en/en_US.dic
```

German:

```command
$ wget -O ~/Library/Spelling/de_DE.dic https://cgit.freedesktop.org/libreoffice/dictionaries/plain/de/de_DE_frami.dic
$ wget -O ~/Library/Spelling/de_DE.aff https://cgit.freedesktop.org/libreoffice/dictionaries/plain/de/de_DE_frami.aff
```

Italian (for integration tests):

```command
$ wget -O ~/Library/Spelling/it_IT.dic https://cgit.freedesktop.org/libreoffice/dictionaries/plain/it_IT/it_IT.dic
$ wget -O ~/Library/Spelling/it_IT.aff https://cgit.freedesktop.org/libreoffice/dictionaries/plain/it_IT/it_IT.aff
```
