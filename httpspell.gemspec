# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'httpspell/version'

Gem::Specification.new do |spec|
  spec.name          = 'httpspell'
  spec.version       = HttpSpell::VERSION
  spec.authors       = ['Steffen Uhlig']
  spec.email         = ['steffen@familie-uhlig.net']

  spec.summary       = 'HTTP spellchecker'
  spec.description   = %(httpspell is a spellchecker that recursively fetches
  HTML pages, converts them to plain text using pandoc, and
  spellchecks them with hunspell.)
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'addressable'
  spec.add_dependency 'nokogiri'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
