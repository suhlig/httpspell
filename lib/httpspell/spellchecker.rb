module HttpSpell
  class SpellChecker
    def initialize(personal_dictionary_path = nil, verbose: false)
      @personal_dictionary_arg = "-p #{personal_dictionary_path}" if personal_dictionary_path
      @verbose = verbose
    end

    def check(doc, lang)
      commands = [
        'pandoc --from html --to plain',
        "hunspell -d #{translate(lang)} #{@personal_dictionary_arg} -i UTF-8 -l",
      ]

      if @verbose
        warn "Piping the HTML document into the following chain of commands:"
        warn commands
      end

      Open3.pipeline_rw(*commands) do |stdin, stdout, _wait_thrs|
        stdin.puts(doc)
        stdin.close
        stdout.read.split.uniq
      end
    end

    private

    # The W3C [recommends](https://www.w3.org/International/questions/qa-html-language-declarations)
    # to specify language using identifiers as per [RFC 5646](https://tools.ietf.org/html/rfc5646)
    # which uses dashes. Hunspell, however, uses underscores. This method translates RFC-style identifiers
    # to hunspell-style.
    def translate(lang)
      lang.tr('-', '_')
    end
  end
end
