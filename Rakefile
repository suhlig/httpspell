# frozen_string_literal: true

require 'rspec/core/rake_task'
require 'bundler/gem_tasks'
require 'rubocop/rake_task'

RuboCop::RakeTask.new

task default: ['spec:all']

namespace :spec do
  desc 'Run all specs'
  task all: %i[rubocop:autocorrect unit system]

  %w[unit system].each do |type|
    desc "Run #{type} tests"
    RSpec::Core::RakeTask.new(type) do |t|
      t.pattern = "spec/#{type}/**/*_spec.rb"
    end
  end
end
