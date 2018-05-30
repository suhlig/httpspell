require 'nokogiri'
require 'open-uri'
require 'open3'
require 'addressable/uri'

module HttpSpell
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  class Spider
    attr_reader :todo, :done

    def initialize(starting_point, base_url = starting_point)
      @todo = []
      @done = []
      todo << Addressable::URI.parse(starting_point)
      @base_url = Addressable::URI.parse(base_url)
    end

    def start
      while todo.any?
        url = todo.pop

        begin
          extracted = links(url) do |u, d|
            yield u, d if block_given?
          end
        rescue StandardError
          warn "Error opening #{url}: #{$ERROR_INFO}"
        end

        done.append(url)
        todo.concat(extracted - done - todo)
      end
    end

    private

    def links(uri)
      # We are using open-uri, which follows redirects and also provides the content-type.
      response = URI(uri).read
      return [] unless response.content_type == 'text/html'
      doc = Nokogiri::HTML(response)

      links = doc.css('a[href]').map do |e|
        link = Addressable::URI.parse(e['href'])
        link = uri.join(link) if link.relative?
        next unless link.to_s.start_with?(@base_url.to_s)
        link
      rescue StandardError
        warn $ERROR_INFO
      end.compact

      yield uri, doc if block_given?
      links
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
end
