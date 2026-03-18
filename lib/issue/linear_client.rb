# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

module Issue
  module LinearClient
    MUTATION = <<~GQL.gsub(/\s+/, ' ').strip
      mutation CreateIssue($teamId: String!, $title: String!, $description: String!) {
        issueCreate(input: { teamId: $teamId, title: $title, description: $description }) {
          success
          issue { identifier title url branchName }
        }
      }
    GQL

    module_function

    def create_issue(token:, team_id:, title:, description:)
      payload = {
        query: MUTATION,
        variables: { teamId: team_id, title: title, description: description }
      }

      uri = URI('https://api.linear.app/graphql')
      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = token
      request['Content-Type'] = 'application/json'
      request.body = JSON.generate(payload)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        warn "Error: Linear API returned HTTP #{response.code}."
        warn response.body
        exit 1
      end

      data = Helpers.parse_json(response.body)
      unless data
        warn 'Error: invalid response from Linear.'
        warn response.body
        exit 1
      end

      if data['errors'].is_a?(Array) && !data['errors'].empty?
        warn 'Error: Linear returned errors.'
        warn JSON.pretty_generate(data['errors'])
        exit 1
      end

      issue_create = data.dig('data', 'issueCreate') || {}
      unless issue_create['success'] == true
        warn 'Error: issueCreate was not successful.'
        warn JSON.pretty_generate(data)
        exit 1
      end

      issue_create['issue'] || {}
    end
  end
end
