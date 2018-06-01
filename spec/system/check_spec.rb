# frozen_string_literal: true

require 'aruba/rspec'
require 'stub_server'

describe 'check', type: 'aruba' do
  let(:httpspell) { "bundle exec #{aruba.root_directory}/exe/httpspell" }
  let(:replies) do
    {
       '/nowhere' => [404, {'content-type' => 'text/html'}, ['does not exist']],
    }
  end

  let(:port) { rand((40000..50000)) }

  around(:example) do |example|
    StubServer.open(port, replies) do |server|
      server.wait
      example.run
    end
  end

  it 'complains about a non-existing starting point' do
    run "#{httpspell} http://localhost:#{port}/nowhere"
    expect(last_command_started).not_to be_successfully_executed
    expect(last_command_started.exit_status).to eq(2)
  end

  context 'content without spelling errors' do
    let(:url) { "http://localhost:#{port}/no-errors.html" }
    let(:replies) do
      {
         '/no-errors.html' => [200, {'content-type' => 'text/html'}, fixture('en_US/no-errors.html')],
      }
    end

    it 'has an exit code of 0' do
      run "#{httpspell} #{url}"
      expect(last_command_started).to be_successfully_executed
    end

    it 'is silent' do
      run "#{httpspell} #{url}"
      expect(last_command_started).not_to have_output
    end
  end

  context 'content with one spelling error' do
    let(:url) { "http://localhost:#{port}/single-spelling-error.html" }
    let(:replies) do
      {
         '/single-spelling-error.html' => [200, {'content-type' => 'text/html'}, fixture('en_US/single-spelling-error.html')],
      }
    end

    it 'has an exit code of 0' do
      run "#{httpspell} #{url}"
      stop_all_commands
      expect(last_command_started.exit_status).to eq(1)
    end

    it 'prints unknown words' do
      run "#{httpspell} #{url}"
      expect(last_command_started).to have_output('Jabberwocky')
    end
  end

  context 'broken links' do
    let(:replies) do
      {
        '/no-error-broken-link.html' => [200, {'content-type' => 'text/html'}, fixture('en_US/no-error-broken-link.html')],
      }
    end

    it 'complains about a broken link' do
      run "#{httpspell} --whitelist http://localhost:#{port}/ http://localhost:#{port}/no-error-broken-link.html"
      expect(last_command_started).not_to be_successfully_executed
      expect(last_command_started.exit_status).to eq(2)
      expect(last_command_started).to have_output(/nowhere/)
    end
  end

  context 'links to page that is blacklisted' do
    let(:url) { "http://localhost:#{port}/link-to-error.html" }
    let(:replies) do
      {
        '/single-spelling-error.html' => [200, {'content-type' => 'text/html'}, fixture('en_US/single-spelling-error.html')],
        '/link-to-error.html' => [200, {'content-type' => 'text/html'}, fixture('en_US/link-to-error.html')],
      }
    end

    it 'ignores blacklisted URLs' do
      run "#{httpspell} --blacklist single-spelling-error.html #{url}"
      expect(last_command_started).to be_successfully_executed
      expect(last_command_started.stdout).to be_empty
    end
  end

  context 'page with some broken links' do
    let(:url) { "http://localhost:#{port}/broken-and-link-to-good.html" }
    let(:replies) do
      {
        '/broken-and-link-to-good.html' => [200, {'content-type' => 'text/html'}, fixture('en_US/broken-and-link-to-good.html')],
        '/nowhere' => [404, {'content-type' => 'text/html'}, ['does not exist']],
        '/single-spelling-error.html' => [200, {'content-type' => 'text/html'}, fixture('en_US/single-spelling-error.html')],
      }
    end

    it 'reports the broken link' do
      run "#{httpspell} --whitelist http://localhost:#{port}/ #{url}"
      expect(last_command_started).not_to be_successfully_executed
      expect(last_command_started.exit_status).to eq(2)
    end

    it 'visits the linked page and reports its errors' do
      run "#{httpspell} --whitelist http://localhost:#{port}/ #{url}"
      expect(last_command_started).not_to be_successfully_executed
      expect(last_command_started.stdout).to match(/Jabberwocky/)
      expect(last_command_started.stderr).to match(/nowhere/)
    end
  end
end
