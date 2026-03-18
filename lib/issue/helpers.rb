# frozen_string_literal: true

require 'json'
require 'open3'

module Issue
  module Helpers
    module_function

    def blank?(value)
      value.to_s.strip.empty?
    end

    def run_cmd(*command)
      stdout, stderr, status = Open3.capture3(*command)
      [stdout, stderr, status]
    end

    def parse_json(text)
      JSON.parse(text)
    rescue JSON::ParserError
      nil
    end

    def decode_json_string(value)
      JSON.parse("\"#{value}\"")
    rescue JSON::ParserError
      value
    end

    def build_branch_name(issue_id, issue_title, branch_name)
      return branch_name unless blank?(branch_name)

      slug = issue_title.to_s.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/^-+|-+$/, '')[0, 55]
      slug = 'issue' if blank?(slug)

      "#{issue_id}-#{slug}".downcase
    end
  end
end
