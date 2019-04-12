require 'nokogiri'
require 'open-uri'
require 'open3'
require 'addressable/uri'
require 'English'

module HttpSpell
  class Spider
    attr_reader :todo, :done

    def initialize(starting_point, whitelist: nil, blacklist: [], tracing: false)
      @todo = []
      @done = []
      todo << Addressable::URI.parse(starting_point)
      @whitelist = whitelist || [/^#{starting_point}/]
      @blacklist = blacklist
      @tracing = tracing
    end

    def start
      success = true

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
          warn "Skipping #{url} because of #{$ERROR_INFO.message}"
          warn $ERROR_INFO.backtrace if @tracing
          success = false
        end
      end

      return success
    end

    private

    def links(uri)
      response = http_get(URI(uri))

      if response.content_type != 'text/html'
        warn "Skipping #{uri} because it is not HTML" if @tracing
        return []
      end

      doc = Nokogiri::HTML(response)

      links = doc.css('a[href]').map do |e|
        link = Addressable::URI.parse(e['href'])
        link = uri.join(link) if link.relative?

        if @whitelist.none? { |re| re.match?(link.to_s) }
          warn "Skipping #{link} because it is not on the whitelist #{@whitelist}" if @tracing
          next
        end

        if @blacklist.any? { |re| re.match?(link.to_s) }
          # TODO Print _which_ entry of the blacklist matches
          warn "Skipping #{link} because it is on the blacklist #{@blacklist}" if @tracing
          next
        end

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

    # https://twin.github.io/improving-open-uri/
    def http_get(uri)
      tries = 10

      begin
        uri.open(redirect: false)
      rescue OpenURI::HTTPRedirect => redirect
        uri = redirect.uri
        retry if (tries -= 1) > 0
        raise
      end
    end
  end
end
