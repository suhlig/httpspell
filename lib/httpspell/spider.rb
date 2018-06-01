require 'nokogiri'
require 'open-uri'
require 'open3'
require 'addressable/uri'
require 'English'

module HttpSpell
  class Spider
    attr_reader :todo, :done

    def initialize(starting_point, limit: nil, tracing: false)
      @todo = []
      @done = []
      todo << Addressable::URI.parse(starting_point)
      @limit = limit || /^#{starting_point}/
      @tracing = tracing
    end

    def start
      while todo.any?
        url = todo.pop
        extracted = links(url) do |u, d|
          yield u, d if block_given?
        rescue
          warn "Callback error for #{url}: #{$ERROR_INFO}"
          warn $ERROR_INFO.backtrace if @tracing
        end

        done.append(url)
        todo.concat(extracted - done - todo)
      end
    end

    private

    def links(uri)
      # We are using open-uri, which follows redirects and also provides the content-type.
      response = open(uri).read

      if response.respond_to?(:content_type)
        return [] unless response.content_type == 'text/html'
      end

      doc = Nokogiri::HTML(response)

      links = doc.css('a[href]').map do |e|
        link = Addressable::URI.parse(e['href'])
        link = uri.join(link) if link.relative?
        next unless @limit.match?(link.to_s)
        # TODO Ignore same page links (some anchor)
        link
      rescue StandardError
        warn $ERROR_INFO.message
        warn $ERROR_INFO.backtrace if @tracing
      end.compact

      yield uri, doc if block_given?

      warn "Adding #{links.size} links from #{uri}" if @tracing
      links
    end
  end
end
