# frozen_string_literal: true

require 'optparse'

module Issue
  class CLI
    def initialize(argv = ARGV)
      @options = parse_options(argv)
    end

    def run
      validate!

      title, description = AnthropicClient.call(
        @options[:description],
        model: @options[:model],
        api_key: @options[:anthropic_key]
      )

      issue = LinearClient.create_issue(
        token: @options[:token],
        team_id: @options[:team_id],
        title: title,
        description: description
      )

      issue_id = issue['identifier'].to_s
      issue_title = issue['title'].to_s
      issue_url = issue['url'].to_s
      branch_name = issue['branchName'].to_s
      branch = Helpers.build_branch_name(issue_id, issue_title, branch_name)

      puts "Issue: #{issue_id}" unless Helpers.blank?(issue_id)
      puts "URL: #{issue_url}" unless Helpers.blank?(issue_url)
      puts "Branch: #{branch}"
      puts "Running: workmux add \"#{branch}\""

      workmux_stdout, workmux_stderr, workmux_status = Helpers.run_cmd('workmux', 'add', branch)
      print workmux_stdout unless workmux_stdout.empty?
      warn workmux_stderr unless workmux_stderr.empty?

      exit(workmux_status.success? ? 0 : 1)
    end

    private

    def parse_options(argv)
      options = {
        model: AnthropicClient::DEFAULT_MODEL
      }

      parser = OptionParser.new do |opts|
        opts.banner = 'Usage: issue "description" [options]'

        opts.on('-t', '--team-id ID', 'Linear Team ID') { |v| options[:team_id] = v }
        opts.on('-k', '--token TOKEN', 'Linear API token') { |v| options[:token] = v }
        opts.on('-a', '--anthropic-key KEY', 'Anthropic API key') { |v| options[:anthropic_key] = v }
        opts.on('-m', '--model MODEL', "Anthropic model (default: #{AnthropicClient::DEFAULT_MODEL})") { |v| options[:model] = v }
        opts.on('-V', '--version', 'Show version') do
          puts "issue #{VERSION}"
          exit 0
        end
        opts.on('-h', '--help', 'Show help') do
          puts opts
          puts "\nRequires ANTHROPIC_API_KEY, LINEAR_API_KEY and LINEAR_TEAM_ID (or their flags)."
          exit 0
        end
      end

      begin
        parser.parse!(argv)
      rescue OptionParser::ParseError => e
        warn "Error: #{e.message}"
        warn parser
        exit 1
      end

      options[:description] = argv.join(' ').strip

      options[:team_id] = resolve_option(options[:team_id], 'LINEAR_TEAM_ID')
      options[:token] = resolve_option(options[:token], 'LINEAR_API_KEY')
      options[:anthropic_key] = resolve_option(options[:anthropic_key], 'ANTHROPIC_API_KEY')

      options
    end

    def resolve_option(value, env_key)
      v = value.to_s.strip
      return v unless Helpers.blank?(v)

      ENV.fetch(env_key, '').strip
    end

    def validate!
      if Helpers.blank?(@options[:description])
        warn 'Error: missing description. Example: issue "Fix webhook timeout"'
        exit 1
      end

      if Helpers.blank?(@options[:anthropic_key])
        warn 'Error: missing Anthropic API key. Use --anthropic-key or export ANTHROPIC_API_KEY.'
        exit 1
      end

      if Helpers.blank?(@options[:team_id])
        warn 'Error: missing team ID. Use --team-id or export LINEAR_TEAM_ID.'
        exit 1
      end

      return unless Helpers.blank?(@options[:token])

      warn 'Error: missing Linear token. Use --token or export LINEAR_API_KEY.'
      exit 1
    end
  end
end
