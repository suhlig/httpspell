# frozen_string_literal: true

require 'nokogiri'
require 'uri'
require 'open-uri'
require 'open3'
require 'English'

module HttpSpell
  class Spider
    attr_reader :todo, :done

    def initialize(starting_point, whitelist: nil, blacklist: [], verbose: false, tracing: false)
      @todo = []
      @done = []
      todo << URI(starting_point)
      @whitelist = whitelist || [/^#{starting_point}/]
      @blacklist = blacklist
      @verbose = verbose
      @tracing = tracing
    end

    def start
      success = true

      while todo.any?
        url = todo.pop

        begin
          extracted = links(url) do |u, d|
            yield u, d if block_given?
          rescue StandardError
            warn "Callback error for #{url}: #{$ERROR_INFO}"
            warn $ERROR_INFO.backtrace if @tracing
          end

          done.append(url)
          new_links = (extracted - done - todo).uniq

          if new_links.any?
            warn "Adding #{new_links.size} new links found at #{url}" if @verbose
            todo.concat(extracted - done - todo).uniq!
          end
        rescue StandardError
          warn "Skipping #{url} because of #{$ERROR_INFO.message}"
          warn $ERROR_INFO.backtrace if @tracing
          success = false
        end
      end

      success
    end

    private

    def links(uri)
      response = http_get(uri)

      if response.respond_to?(:content_type) && response.content_type != 'text/html'
        warn "Skipping #{response.base_uri} because it is not HTML" if @verbose
        return []
      end

      doc = Nokogiri::HTML(response)

      links = doc.css('a[href]').map do |e|
        next if e['href'].start_with?('#') # Ignore fragment on the same page; we always check the whole page

        link = URI.join(response.base_uri, e['href'])
        link.fragment = nil # Ignore fragment in links to other pages, too

        if @whitelist.none? { |re| re.match?(link.to_s) }
          warn "Skipping #{link} because it is not on the whitelist #{@whitelist}" if @verbose
          next
        end

        if @blacklist.any? { |re| re.match?(link.to_s) }
          # TODO: Print _which_ entry of the blacklist matches
          warn "Skipping #{link} because it is on the blacklist #{@blacklist}" if @verbose
          next
        end

        link
      rescue StandardError
        warn "Error: #{$ERROR_INFO}"
        warn $ERROR_INFO.backtrace if @tracing
      end.compact

      yield response.base_uri, doc if block_given?

      links
    end

    # https://twin.github.io/improving-open-uri/
    def http_get(uri)
      tries = 10
      begin
        URI.parse(uri).open(redirect: false)
      rescue OpenURI::HTTPRedirect => e
        uri = e.uri
        retry if (tries -= 1).positive?
        raise
      end
    end
  end
end
