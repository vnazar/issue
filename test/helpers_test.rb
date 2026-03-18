# frozen_string_literal: true

require 'test_helper'

class HelpersTest < Minitest::Test
  def test_blank_with_nil
    assert Issue::Helpers.blank?(nil)
  end

  def test_blank_with_empty_string
    assert Issue::Helpers.blank?('')
  end

  def test_blank_with_whitespace
    assert Issue::Helpers.blank?('   ')
  end

  def test_blank_with_value
    refute Issue::Helpers.blank?('hello')
  end

  def test_build_branch_name_uses_linear_branch
    result = Issue::Helpers.build_branch_name('ENG-1', 'Some title', 'eng-1-some-title')
    assert_equal 'eng-1-some-title', result
  end

  def test_build_branch_name_generates_from_title
    result = Issue::Helpers.build_branch_name('ENG-1', 'Fix webhook timeout', '')
    assert_equal 'eng-1-fix-webhook-timeout', result
  end

  def test_build_branch_name_slugifies_special_chars
    result = Issue::Helpers.build_branch_name('ENG-2', 'Add retry (with backoff) to API!', '')
    assert_equal 'eng-2-add-retry-with-backoff-to-api', result
  end

  def test_build_branch_name_truncates_long_slugs
    long_title = 'A' * 100
    result = Issue::Helpers.build_branch_name('ENG-3', long_title, '')
    slug_part = result.sub('eng-3-', '')
    assert slug_part.length <= 55
  end

  def test_build_branch_name_fallback_when_title_empty
    result = Issue::Helpers.build_branch_name('ENG-4', '', '')
    assert_equal 'eng-4-issue', result
  end

  def test_parse_json_valid
    result = Issue::Helpers.parse_json('{"a":1}')
    assert_equal({ 'a' => 1 }, result)
  end

  def test_parse_json_invalid
    assert_nil Issue::Helpers.parse_json('not json')
  end

  def test_command_exists_with_ruby
    assert Issue::Helpers.command_exists?('ruby')
  end

  def test_command_exists_with_nonexistent
    refute Issue::Helpers.command_exists?('definitely_not_a_real_command_xyz')
  end
end
