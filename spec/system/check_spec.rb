# frozen_string_literal: true

require 'aruba/rspec'

describe 'check', type: 'aruba' do
  let(:httpspell) { "bundle exec #{aruba.root_directory}/exe/httpspell" }

  context 'using a file URL' do
    it 'complains about a non-existing starting point' do
      run "#{httpspell} /tmp/dead-link"
      expect(last_command_started).not_to be_successfully_executed
      expect(last_command_started.exit_status).to eq(2)
    end

    it 'complains about a broken link' do
      run "#{httpspell} --whitelist #{aruba.root_directory}/spec #{fixture('en_US/no-error-broken-link.html')}"
      expect(last_command_started).not_to be_successfully_executed
      expect(last_command_started.exit_status).to eq(2)
      expect(last_command_started).to have_output(/nowhere/)
    end

    context 'content without spelling errors' do
      let(:file) { fixture('en_US/no-errors.html') }

      it 'is silent' do
        run "#{httpspell} #{file}"
        expect(last_command_started).to be_successfully_executed
        expect(last_command_started).not_to have_output
      end
    end

    context 'content with one spelling error' do
      let(:file) { fixture('en_US/single-spelling-error.html') }

      it 'prints unknown words' do
        run "#{httpspell} #{file}"
        expect(last_command_started).not_to be_successfully_executed
        expect(last_command_started.exit_status).to eq(1)
        expect(last_command_started).to have_output('Jabberwocky')
      end
    end
  end

  context 'using a http URL' do
    context 'does not exist' do
      let(:url) { 'https://example.com/dead-link' }

      it 'complains' do
        run "#{httpspell} #{url}"
        expect(last_command_started).not_to be_successfully_executed
        expect(last_command_started.exit_status).to eq(2)
      end
    end

    context 'content without spelling errors' do
      let(:url) { 'https://example.com' }

      it 'is silent' do
        run "#{httpspell} #{url}"
        expect(last_command_started).to be_successfully_executed
        expect(last_command_started).not_to have_output
      end
    end
  end

  it 'ignores blacklisted URLs' do
    run "#{httpspell} --blacklist single-spelling-error.html --whitelist #{aruba.root_directory}/spec #{fixture('en_US/link-to-error.html')}"
    expect(last_command_started).to be_successfully_executed
    expect(last_command_started.stdout).to be_empty
  end

  context 'page with some broken links' do
    let(:url) { fixture('en_US/broken-and-link-to-good.html') }

    it 'reports the broken link' do
      run "#{httpspell} --whitelist #{aruba.root_directory}/spec #{url}"
      expect(last_command_started).not_to be_successfully_executed
      expect(last_command_started.exit_status).to eq(2)
    end

    it 'visits the linked page and reports its errors' do
      run "#{httpspell} --whitelist #{aruba.root_directory}/spec #{url}"
      expect(last_command_started).not_to be_successfully_executed
      expect(last_command_started.stdout).to match(/Jabberwocky/)
      expect(last_command_started.stderr).to match(/nowhere/)
    end
  end
end
