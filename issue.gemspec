# frozen_string_literal: true

require_relative 'lib/issue/version'

Gem::Specification.new do |spec|
  spec.name          = 'issue'
  spec.version       = Issue::VERSION
  spec.authors       = ['Vicente']
  spec.summary       = 'CLI that creates Linear issues with AI and sets up worktrees via workmux'
  spec.homepage      = 'https://github.com/vicente/linear_wm'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.0'

  spec.files         = Dir['lib/**/*.rb', 'bin/*', 'LICENSE', 'README.md']
  spec.bindir        = 'bin'
  spec.executables   = ['issue']

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
end
