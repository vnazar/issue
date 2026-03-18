# frozen_string_literal: true

require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
end

task default: :test

desc 'Bump version and create a release tag. Usage: rake release[patch|minor|major]'
task :release, [:bump] do |_t, args|
  bump = args[:bump] || 'patch'
  unless %w[patch minor major].include?(bump)
    abort "Error: invalid bump type '#{bump}'. Use patch, minor, or major."
  end

  version_file = 'lib/issue/version.rb'
  content = File.read(version_file)
  current = content.match(/VERSION = '(\d+\.\d+\.\d+)'/)[1]
  major, minor, patch = current.split('.').map(&:to_i)

  case bump
  when 'major' then major += 1; minor = 0; patch = 0
  when 'minor' then minor += 1; patch = 0
  when 'patch' then patch += 1
  end

  new_version = "#{major}.#{minor}.#{patch}"
  File.write(version_file, content.sub(current, new_version))

  sh "git add #{version_file}"
  sh "git commit -m 'release: v#{new_version}'"
  sh "git tag v#{new_version}"
  sh "git push && git push --tags"

  puts "Released v#{new_version}"
end
