# frozen_string_literal: true

require 'http_spell/spider'
require 'stub_server'

describe HttpSpell::Spider do
  attr_reader :success

  around do |example|
    StubServer.open(9123, replies) do |server|
      server.wait
      example.run
    end
  end

  let(:whitelist) { [Regexp.new("^#{starting_point}")] }

  before do
    @success = described_class.new(starting_point, whitelist:).start do |url, _doc|
      links << url.to_s
    end
  end

  describe 'when a document has duplicate links' do
    let(:starting_point) { 'http://localhost:9123/' }

    let(:replies) do
      {
        '/' => [200, { 'content-type' => 'text/html' }, ['<a href="/foo.html">foo</a><a href="/bar.html">bar</a>']],
        '/foo.html' => [200, { 'content-type' => 'text/html' }, ['<a href="/">home</a><a href="/bar.html">bar</a>']],
        '/bar.html' => [200, { 'content-type' => 'text/html' }, ['<a href="/">home</a><a href="/foo.html">foo</a>']]
      }
    end

    it 'does not visit the same link twice' do
      expect(links).to eq(
        [
          'http://localhost:9123/',
          'http://localhost:9123/bar.html',
          'http://localhost:9123/foo.html',
        ]
      )
    end
  end

  describe 'when a document has a host-relative link with an absolute path' do
    let(:starting_point) { 'http://localhost:9123/foo/bar.html' }
    let(:whitelist) { [Regexp.new('^http://localhost:9123/')] }

    let(:replies) do
      {
        '/foo/bar.html' => [200, { 'content-type' => 'text/html' }, ['<a href="/foobar.html">foobar</a>']],
        '/foobar.html' => [200, { 'content-type' => 'text/html' }, []]
      }
    end

    it 'visits the link' do
      expect(links).to eq(
        [
          'http://localhost:9123/foo/bar.html',
          'http://localhost:9123/foobar.html',
        ]
      )
    end
  end

  describe 'when a document with extension has host-relative link with a relative path' do
    let(:starting_point) { 'http://localhost:9123/foo/bar.html' }
    let(:whitelist) { [Regexp.new('^http://localhost:9123/foo/')] }

    let(:replies) do
      {
        '/foo/bar.html' => [200, { 'content-type' => 'text/html' }, ['<a href="baz.html">baz</a>']],
        '/foo/baz.html' => [200, { 'content-type' => 'text/html' }, []]
      }
    end

    it 'visits the link' do
      expect(links).to eq(
        [
          'http://localhost:9123/foo/bar.html',
          'http://localhost:9123/foo/baz.html',
        ]
      )
    end
  end

  describe 'when a document without extension has host-relative link with a relative path' do
    let(:starting_point) { 'http://localhost:9123/foo/' }
    let(:whitelist) { [Regexp.new('^http://localhost:9123/foo/')] }

    let(:replies) do
      {
        '/foo/' => [200, { 'content-type' => 'text/html' }, ['<a href="baz.html">baz</a>']],
        '/foo/baz.html' => [200, { 'content-type' => 'text/html' }, []]
      }
    end

    it 'visits the link' do
      expect(links).to eq(
        [
          'http://localhost:9123/foo/',
          'http://localhost:9123/foo/baz.html',
        ]
      )
    end
  end

  describe 'when the server redirects' do
    let(:starting_point) { 'http://localhost:9123/foo' }
    let(:whitelist) { [Regexp.new('^http://localhost:9123/')] }

    let(:replies) do
      {
        '/foo' => [301, { 'Location' => '/foo/' }, []],
        '/foo/' => [200, { 'content-type' => 'text/html' }, []]
      }
    end

    it 'returns the location redirected to' do
      expect(links).to eq(
        [
          'http://localhost:9123/foo/',
        ]
      )
    end
  end

  describe 'when a document has a document-relative link (just the fragment)' do
    let(:starting_point) { 'http://localhost:9123/' }

    describe 'to the same document' do
      let(:replies) do
        {
          '/' => [200, { 'content-type' => 'text/html' }, ['<a href="#nav">nav</a>']]
        }
      end

      it 'does not visit the link' do
        expect(links).to eq(['http://localhost:9123/'])
      end
    end

    describe 'to another document' do
      let(:replies) do
        {
          '/' => [200, { 'content-type' => 'text/html' }, ['<a href="foo.html#nav">foo nav</a>']],
          '/foo.html' => [200, { 'content-type' => 'text/html' }, []]
        }
      end

      it 'visits the fragment-less link' do
        expect(links).to eq([
                              'http://localhost:9123/',
                              'http://localhost:9123/foo.html',
                            ])
      end
    end
  end

  describe 'one link' do
    let(:starting_point) { 'http://localhost:9123/' }

    let(:replies) do
      {
        '/' => [200, { 'content-type' => 'text/html' }, ['<a href="foo.html">foo</a>']],
        '/foo.html' => [200, { 'content-type' => 'text/html' }, []]
      }
    end

    it 'works' do
      expect(success).to be_truthy
    end

    it 'finds the expected links' do
      expect(links).to eq(
        [
          'http://localhost:9123/',
          'http://localhost:9123/foo.html',
        ]
      )
    end
  end

  describe 'link with anchor' do
    let(:starting_point) { 'http://localhost:9123/' }

    let(:replies) do
      {
        '/' => [200, { 'content-type' => 'text/html' }, ['<a href="#something">something</a>']]
      }
    end

    it 'works' do
      expect(success).to be_truthy
    end

    it 'finds the expected links' do
      expect(links).to eq(['http://localhost:9123/',])
    end
  end

  describe 'duplicate links' do
    let(:starting_point) { 'http://localhost:9123/' }

    let(:replies) do
      {
        '/' => [200, { 'content-type' => 'text/html' }, [%(
          <ul>
          <li><a href="foo.html">foo</a>
          <li><a href="foo.html">foo</a>
          <li><a href="foo.html#bar">bar</a>
          </ul>
          )]],
        '/foo.html' => [200, { 'content-type' => 'text/html' }, []]
      }
    end

    it 'works' do
      expect(success).to be_truthy
    end

    it 'produces no duplicate links' do
      expect(links).to eq(
        [
          'http://localhost:9123/',
          'http://localhost:9123/foo.html',
        ]
      )
    end
  end
end

def links
  @links ||= []
end
