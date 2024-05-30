# frozen_string_literal: true

require 'aruba/rspec'

describe 'help', type: 'aruba' do
  before do
    run_command "bundle exec #{aruba.root_directory}/exe/httpspell -h"
  end

  it 'executes without error' do
    expect(last_command_started).to be_successfully_executed
  end

  it 'prints usage' do
    expect(last_command_started).to have_output(/spell/)
  end
end
