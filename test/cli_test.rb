# frozen_string_literal: true

require 'test_helper'

class CLIWorktreeTest < Minitest::Test
  include TestSupport

  def setup
    Issue::Config.instance_variable_set(:@data, nil)
  end

  def teardown
    Issue::Config.instance_variable_set(:@data, nil)
  end

  def base_env
    {
      'ANTHROPIC_API_KEY' => 'test-key',
      'LINEAR_API_KEY' => 'test-token',
      'LINEAR_TEAM_ID' => 'team-123'
    }
  end

  # --- workmux vs git worktree ---

  def test_uses_workmux_when_available
    result = run_cli(
      ['Fix timeout'],
      env: base_env,
      command_exists: { 'workmux' => true },
      run_cmd_responses: { 'workmux' => ["Worktree created\n", '', FakeStatus.success] }
    )

    assert_equal 0, result[:exit_code]
    assert_equal %w[workmux add eng-123-fix-timeout], result[:run_cmd_calls].last
    assert_includes result[:stdout], 'workmux add'
  end

  def test_falls_back_to_git_worktree_when_workmux_missing
    result = run_cli(
      ['Fix timeout'],
      env: base_env,
      command_exists: { 'workmux' => false },
      run_cmd_responses: { 'git' => ["Worktree created\n", '', FakeStatus.success] }
    )

    assert_equal 0, result[:exit_code]
    assert_equal %w[git worktree add eng-123-fix-timeout], result[:run_cmd_calls].last
    assert_includes result[:stdout], 'git worktree add'
  end

  def test_exits_with_1_when_workmux_fails
    result = run_cli(
      ['Fix timeout'],
      env: base_env,
      command_exists: { 'workmux' => true },
      run_cmd_responses: { 'workmux' => ['', "error: branch exists\n", FakeStatus.failure] }
    )

    assert_equal 1, result[:exit_code]
    assert_includes result[:stderr], 'error: branch exists'
  end

  def test_exits_with_1_when_git_worktree_fails
    result = run_cli(
      ['Fix timeout'],
      env: base_env,
      command_exists: { 'workmux' => false },
      run_cmd_responses: { 'git' => ['', "fatal: branch exists\n", FakeStatus.failure] }
    )

    assert_equal 1, result[:exit_code]
    assert_includes result[:stderr], 'fatal: branch exists'
  end

  def test_prints_workmux_stdout
    result = run_cli(
      ['Fix timeout'],
      env: base_env,
      command_exists: { 'workmux' => true },
      run_cmd_responses: { 'workmux' => ["Created worktree at ../eng-123\n", '', FakeStatus.success] }
    )

    assert_includes result[:stdout], 'Created worktree at ../eng-123'
  end

  def test_prints_git_worktree_stdout
    result = run_cli(
      ['Fix timeout'],
      env: base_env,
      command_exists: { 'workmux' => false },
      run_cmd_responses: { 'git' => ["Preparing worktree\n", '', FakeStatus.success] }
    )

    assert_includes result[:stdout], 'Preparing worktree'
  end

  def test_passes_branch_name_from_linear
    result = run_cli(
      ['Fix timeout'],
      env: base_env,
      command_exists: { 'workmux' => true },
      run_cmd_responses: { 'workmux' => ['', '', FakeStatus.success] }
    )

    assert_equal 'eng-123-fix-timeout', result[:run_cmd_calls].last.last
  end

  # --- output ---

  def test_prints_issue_id_and_url
    result = run_cli(
      ['Fix timeout'],
      env: base_env,
      command_exists: { 'workmux' => true },
      run_cmd_responses: { 'workmux' => ['', '', FakeStatus.success] }
    )

    assert_includes result[:stdout], 'Issue: ENG-123'
    assert_includes result[:stdout], 'URL: https://linear.app/team/issue/ENG-123'
    assert_includes result[:stdout], 'Branch: eng-123-fix-timeout'
  end
end

class CLIValidationTest < Minitest::Test
  include TestSupport

  def setup
    Issue::Config.instance_variable_set(:@data, nil)
  end

  def teardown
    Issue::Config.instance_variable_set(:@data, nil)
  end

  def test_exits_with_error_when_no_description
    result = run_cli(
      [],
      env: { 'ANTHROPIC_API_KEY' => 'k', 'LINEAR_API_KEY' => 't', 'LINEAR_TEAM_ID' => 'x' }
    )

    assert_equal 1, result[:exit_code]
    assert_includes result[:stderr], 'missing description'
  end

  def test_exits_with_error_when_no_anthropic_key
    result = run_cli(
      ['Fix bug'],
      env: { 'ANTHROPIC_API_KEY' => '', 'LINEAR_API_KEY' => 't', 'LINEAR_TEAM_ID' => 'x' }
    )

    assert_equal 1, result[:exit_code]
    assert_includes result[:stderr], 'ANTHROPIC_API_KEY'
  end

  def test_exits_with_error_when_no_team
    result = run_cli(
      ['Fix bug'],
      env: { 'ANTHROPIC_API_KEY' => 'k', 'LINEAR_API_KEY' => 't', 'LINEAR_TEAM_ID' => '' }
    )

    assert_equal 1, result[:exit_code]
    assert_includes result[:stderr], 'missing team'
  end

  def test_exits_with_error_when_no_linear_token
    result = run_cli(
      ['Fix bug'],
      env: { 'ANTHROPIC_API_KEY' => 'k', 'LINEAR_API_KEY' => '', 'LINEAR_TEAM_ID' => 'x' }
    )

    assert_equal 1, result[:exit_code]
    assert_includes result[:stderr], 'LINEAR_API_KEY'
  end

  def test_team_flag_overrides_env
    result = run_cli(
      ['--team', 'flag-team', 'Fix bug'],
      env: { 'ANTHROPIC_API_KEY' => 'k', 'LINEAR_API_KEY' => 't', 'LINEAR_TEAM_ID' => 'env-team' },
      command_exists: { 'workmux' => false },
      run_cmd_responses: { 'git' => ['', '', FakeStatus.success] }
    )

    assert_equal 0, result[:exit_code]
  end

  def test_team_from_config_when_no_flag_or_env
    Issue::Config.instance_variable_set(:@data, { 'team' => 'config-team' })

    result = run_cli(
      ['Fix bug'],
      env: { 'ANTHROPIC_API_KEY' => 'k', 'LINEAR_API_KEY' => 't', 'LINEAR_TEAM_ID' => '' },
      command_exists: { 'workmux' => false },
      run_cmd_responses: { 'git' => ['', '', FakeStatus.success] }
    )

    assert_equal 0, result[:exit_code]
  end

  def test_status_from_config
    Issue::Config.instance_variable_set(:@data, { 'status' => 'config-state-uuid' })

    result = run_cli(
      ['Fix bug'],
      env: { 'ANTHROPIC_API_KEY' => 'k', 'LINEAR_API_KEY' => 't', 'LINEAR_TEAM_ID' => 'x' },
      command_exists: { 'workmux' => false },
      run_cmd_responses: { 'git' => ['', '', FakeStatus.success] }
    )

    assert_equal 0, result[:exit_code]
  end
end
