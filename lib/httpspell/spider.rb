require 'nokogiri'
require 'open-uri'
require 'open3'
require 'addressable/uri'
require 'English'

module HttpSpell
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  class Spider
    attr_reader :todo, :done

    def initialize(starting_point, base_url = starting_point, tracing: false)
      @todo = []
      @done = []
      todo << Addressable::URI.parse(starting_point)
      @base_url = Addressable::URI.parse(base_url)
      @tracing = tracing
    end

    def start
      while todo.any?
        url = todo.pop

        begin
          extracted = links(url) do |u, d|
            yield u, d if block_given?
          rescue
            warn "Callback error for #{url}: #{$ERROR_INFO}"
            warn $ERROR_INFO.backtrace if @tracing
          end

          done.append(url)
          todo.concat(extracted - done - todo)
        rescue StandardError
          warn "Could not fetch #{url}: #{$ERROR_INFO}"
          warn $ERROR_INFO.backtrace if @tracing
        end
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
        next unless link.to_s.start_with?(@base_url.to_s)
        # TODO Ignore same page links (some some anchor)
        link
      rescue StandardError
        warn $ERROR_INFO.message
        warn $ERROR_INFO.backtrace if @tracing
      end.compact

      yield uri, doc if block_given?
      links
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
end
