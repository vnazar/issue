# frozen_string_literal: true

require 'minitest/autorun'
require 'issue'

module TestSupport
  FakeStatus = Struct.new(:success?) do
    def self.success = new(true)
    def self.failure = new(false)
  end

  FAKE_ISSUE = {
    'identifier' => 'ENG-123',
    'title' => 'Fix timeout',
    'url' => 'https://linear.app/team/issue/ENG-123',
    'branchName' => 'eng-123-fix-timeout'
  }.freeze

  STUB_TARGETS = {
    helpers: Issue::Helpers,
    anthropic: Issue::AnthropicClient,
    linear: Issue::LinearClient
  }.freeze

  def run_cli(argv, env: {}, command_exists: {}, run_cmd_responses: {})
    stdout_buf = StringIO.new
    stderr_buf = StringIO.new
    exit_code = nil
    run_cmd_calls = []

    saved_env = env.to_h { |k, _| [k, ENV[k]] }
    env.each { |k, v| ENV[k] = v }

    stubs = {
      %i[helpers command_exists?] => ->(name) { command_exists.fetch(name, false) },
      %i[helpers run_cmd] => lambda { |*cmd|
        run_cmd_calls << cmd
        run_cmd_responses.fetch(cmd.first, ['', '', FakeStatus.success])
      },
      %i[anthropic call] => ->(_desc, api_key:) { ['Fix timeout', 'The webhook times out after 30 seconds'] },
      %i[linear create_issue] => ->(**_kw) { FAKE_ISSUE }
    }

    originals = stubs.to_h { |key, _| [key, STUB_TARGETS[key.first].method(key.last)] }
    stubs.each { |(mod, name), impl| STUB_TARGETS[mod].singleton_class.define_method(name, &impl) }

    old_stdout = $stdout
    old_stderr = $stderr
    $stdout = stdout_buf
    $stderr = stderr_buf

    begin
      Issue::CLI.new(argv).run
    rescue SystemExit => e
      exit_code = e.status
    ensure
      $stdout = old_stdout
      $stderr = old_stderr
      saved_env.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
      originals.each { |(mod, name), method| STUB_TARGETS[mod].singleton_class.define_method(name, method) }
    end

    { exit_code: exit_code, stdout: stdout_buf.string, stderr: stderr_buf.string, run_cmd_calls: run_cmd_calls }
  end
end
