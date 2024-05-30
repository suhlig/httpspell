# frozen_string_literal: true

require 'aruba/rspec'
require 'stub_server'
require 'httpx'

dictionaries = {
  'https://cgit.freedesktop.org/libreoffice/dictionaries/plain/en/en_US.aff' => 'en_US.aff',
  'https://cgit.freedesktop.org/libreoffice/dictionaries/plain/en/en_US.dic' => 'en_US.dic',
  'https://cgit.freedesktop.org/libreoffice/dictionaries/plain/de/de_DE_frami.dic' => 'de_DE.dic',
  'https://cgit.freedesktop.org/libreoffice/dictionaries/plain/de/de_DE_frami.aff' => 'de_DE.aff',
  'https://cgit.freedesktop.org/libreoffice/dictionaries/plain/it_IT/it_IT.dic' => 'it_IT.dic',
  'https://cgit.freedesktop.org/libreoffice/dictionaries/plain/it_IT/it_IT.aff' => 'it_IT.aff'
}

describe 'check', type: 'aruba' do
  let(:httpspell) do
    ENV['DICPATH'] = "#{aruba.root_directory}/spec/dictionaries"
    "bundle exec #{aruba.root_directory}/exe/httpspell"
  end

  let(:replies) do
    { '/nowhere' => [404, { 'content-type' => 'text/html' }, ['does not exist']] }
  end

  let(:port) { rand((40_000..50_000)) }

  # rubocop:disable RSpec/BeforeAfterAll
  before(:all) do
    dictionaries.transform_values! do |file_name|
      "#{aruba.root_directory}/spec/dictionaries/#{file_name}"
    end

    dictionaries.delete_if { |_, file_name| File.exist?(file_name) }

    unless dictionaries.empty?
      warn "Downloading #{dictionaries.size} dictionaries"

      HTTPX.plugin(:callbacks).on_response_completed do |request, response|
        raise if response.error

        file_name = dictionaries[request.uri.to_s]
        raise "no file name for #{request.uri}" unless file_name

        File.write(file_name, response.body)
      end.get(*dictionaries.keys)
    end
  end
  # rubocop:enable RSpec/BeforeAfterAll

  around do |example|
    StubServer.open(port, replies) do |server|
      server.wait
      example.run
    end
  end

  describe 'non-existing starting point' do
    before do
      run_command "#{httpspell} http://localhost:#{port}/nowhere"
      stop_all_commands
    end

    it 'complains' do
      expect(last_command_started).not_to be_successfully_executed
    end

    it 'has the expected exit code' do
      expect(last_command_started.exit_status).to eq(2)
    end
  end

  context 'when the content has no spelling errors' do
    let(:url) { "http://localhost:#{port}/no-errors.html" }

    let(:replies) do
      { '/no-errors.html' => [200, { 'content-type' => 'text/html' }, fixture('en_US/no-errors.html')] }
    end

    before do
      run_command "#{httpspell} #{url}"
      stop_all_commands
    end

    it 'has an exit code of 0' do
      expect(last_command_started).to be_successfully_executed
    end

    it 'is silent' do
      expect(last_command_started).not_to have_output
    end
  end

  context 'when mixed-language content has no spelling errors' do
    let(:url) { "http://localhost:#{port}/mixed/no-errors.html" }

    let(:replies) do
      { '/mixed/no-errors.html' => [200, { 'content-type' => 'text/html' }, fixture('mixed/no-errors.html')] }
    end

    before do
      run_command "#{httpspell} #{url}"
      stop_all_commands
    end

    it 'has an exit code of 0' do
      expect(last_command_started).to be_successfully_executed
    end

    it 'is silent' do
      expect(last_command_started).not_to have_output
    end
  end

  context 'when the content has one spelling error' do
    let(:url) { "http://localhost:#{port}/single-spelling-error.html" }

    let(:replies) do
      {
        '/single-spelling-error.html' => [200, { 'content-type' => 'text/html' }, fixture('en_US/single-spelling-error.html')]
      }
    end

    before do
      run_command "#{httpspell} #{url}"
      stop_all_commands
    end

    it 'has an exit code of 0' do
      expect(last_command_started.exit_status).to eq(1)
    end

    it 'prints unknown words' do
      expect(last_command_started).to have_output('Jabberwocky')
    end
  end

  context 'when there are broken links' do
    let(:replies) do
      { '/no-error-broken-link.html' => [200, { 'content-type' => 'text/html' }, fixture('en_US/no-error-broken-link.html')] }
    end

    before do
      run_command "#{httpspell} --whitelist http://localhost:#{port}/ http://localhost:#{port}/no-error-broken-link.html"
      stop_all_commands
    end

    it 'fails' do
      expect(last_command_started).not_to be_successfully_executed
    end

    it 'has the expected exit status' do
      expect(last_command_started.exit_status).to eq(2)
    end

    it 'complains' do
      expect(last_command_started).to have_output(/nowhere/)
    end
  end

  context 'when the content has links to a page that is blacklisted' do
    let(:url) { "http://localhost:#{port}/link-to-error.html" }

    let(:replies) do
      {
        '/single-spelling-error.html' => [200, { 'content-type' => 'text/html' }, fixture('en_US/single-spelling-error.html')],
        '/link-to-error.html' => [200, { 'content-type' => 'text/html' }, fixture('en_US/link-to-error.html')]
      }
    end

    before do
      run_command "#{httpspell} --blacklist single-spelling-error.html #{url}"
      stop_all_commands
    end

    it 'succeeds' do
      expect(last_command_started).to be_successfully_executed
    end

    it 'ignores blacklisted URLs' do
      expect(last_command_started.stdout).to be_empty
    end
  end

  context 'when the page has spelling errors and also some broken links' do
    let(:url) { "http://localhost:#{port}/broken-and-link-to-good.html" }

    let(:replies) do
      {
        '/broken-and-link-to-good.html' => [200, { 'content-type' => 'text/html' }, fixture('en_US/broken-and-link-to-good.html')],
        '/nowhere' => [404, { 'content-type' => 'text/html' }, ['does not exist']],
        '/single-spelling-error.html' => [200, { 'content-type' => 'text/html' }, fixture('en_US/single-spelling-error.html')]
      }
    end

    before do
      run_command "#{httpspell} --whitelist http://localhost:#{port}/ #{url}"
      stop_all_commands
    end

    it 'fails' do
      expect(last_command_started).not_to be_successfully_executed
    end

    it 'has the expected exit status' do
      expect(last_command_started.exit_status).to eq(2)
    end

    it 'reports the first error of the linked page' do
      expect(last_command_started.stdout).to match(/Jabberwocky/)
    end

    it 'reports the second error of the linked page' do
      expect(last_command_started.stderr).to match(/nowhere/)
    end
  end
end
