# frozen_string_literal: true

require 'aruba/rspec'

describe 'check', type: 'aruba' do
  let(:httpspell) { "bundle exec #{aruba.root_directory}/exe/httpspell" }

  context 'when using a file URL' do
    it 'complains about a non-existing starting point' do
      run "#{httpspell} /tmp/dead-link"
      expect(last_command_started).not_to be_successfully_executed
      expect(last_command_started.exit_status).to eq(2)
    end

    it 'complains about a broken link' do
      run "#{httpspell} --limit #{aruba.root_directory}/spec #{fixture('en_US/no-error-broken-link.html')}"
      expect(last_command_started).not_to be_successfully_executed
      expect(last_command_started.exit_status).to eq(2)
      expect(last_command_started).to have_output(/nowhere/)
    end

    context 'no spelling errors were found' do
      it 'is silent' do
        run "#{httpspell} #{fixture('en_US/no-errors.html')}"
        expect(last_command_started).to be_successfully_executed
        expect(last_command_started).not_to have_output
      end
    end

    context 'one spelling error' do
      it 'prints unknown words' do
        run "#{httpspell} #{fixture('en_US/single-spelling-error')}.html"
        expect(last_command_started).not_to be_successfully_executed
        expect(last_command_started.exit_status).to eq(1)
        expect(last_command_started).to have_output('Jabberwocky')
      end
    end
  end

  context 'using a http URL' do
    it 'complains about a non-existing starting point' do
      run "#{httpspell} https://example.com/dead-link"
      expect(last_command_started).not_to be_successfully_executed
      expect(last_command_started.exit_status).to eq(2)
    end

    context 'no spelling errors were found' do
      it 'is silent' do
        run "#{httpspell} https://example.com"
        expect(last_command_started).to be_successfully_executed
        expect(last_command_started).not_to have_output
      end
    end
  end
end
