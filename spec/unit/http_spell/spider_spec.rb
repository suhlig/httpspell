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

  before do
    @success = described_class.new('http://localhost:9123/').start do |url, _doc|
      links << url.to_s
    end
  end

  describe 'one link' do
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
