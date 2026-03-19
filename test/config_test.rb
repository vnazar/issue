# frozen_string_literal: true

require 'test_helper'

class ConfigTest < Minitest::Test
  def setup
    Issue::Config.instance_variable_set(:@data, nil)
  end

  def teardown
    Issue::Config.instance_variable_set(:@data, nil)
  end

  def test_returns_empty_hash_when_no_file
    stub_const(:CONFIG_PATH, '/tmp/nonexistent_issue_config.yaml') do
      assert_equal({}, Issue::Config.load_file)
    end
  end

  def test_reads_team_from_cached_data
    Issue::Config.instance_variable_set(:@data, { 'team' => 'my-team' })
    assert_equal 'my-team', Issue::Config.team
  end

  def test_reads_model_from_cached_data
    Issue::Config.instance_variable_set(:@data, { 'model' => 'claude-sonnet-4-20250514' })
    assert_equal 'claude-sonnet-4-20250514', Issue::Config.model
  end

  def test_reads_prompt_from_cached_data
    Issue::Config.instance_variable_set(:@data, { 'prompt' => 'custom prompt {{description}}' })
    assert_equal 'custom prompt {{description}}', Issue::Config.prompt
  end

  def test_reads_status_from_cached_data
    Issue::Config.instance_variable_set(:@data, { 'status' => 'state-uuid-123' })
    assert_equal 'state-uuid-123', Issue::Config.status
  end

  def test_returns_nil_for_missing_keys
    Issue::Config.instance_variable_set(:@data, {})
    assert_nil Issue::Config.team
    assert_nil Issue::Config.model
    assert_nil Issue::Config.prompt
    assert_nil Issue::Config.status
  end

  def test_loads_from_yaml_file
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'config.yaml')
      File.write(path, "team: test-team\nmodel: claude-haiku-4-5\n")

      stub_const(:CONFIG_PATH, path) do
        result = Issue::Config.data
        assert_equal 'test-team', result['team']
        assert_equal 'claude-haiku-4-5', result['model']
      end
    end
  end

  private

  def stub_const(const, value)
    original = Issue::Config.const_get(const)
    Issue::Config.send(:remove_const, const)
    Issue::Config.const_set(const, value)
    yield
  ensure
    Issue::Config.send(:remove_const, const)
    Issue::Config.const_set(const, original)
  end
end
