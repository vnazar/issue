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
        api_key: @options[:anthropic_key]
      )

      issue = LinearClient.create_issue(
        token: @options[:token],
        team_id: @options[:team],
        title: title,
        description: description,
        state_id: @options[:status]
      )

      issue_id = issue['identifier'].to_s
      issue_title = issue['title'].to_s
      issue_url = issue['url'].to_s
      branch_name = issue['branchName'].to_s
      branch = Helpers.build_branch_name(issue_id, issue_title, branch_name)

      puts "Issue: #{issue_id}" unless Helpers.blank?(issue_id)
      puts "URL: #{issue_url}" unless Helpers.blank?(issue_url)
      puts "Branch: #{branch}"

      if Helpers.command_exists?('workmux')
        puts "Running: workmux add \"#{branch}\""
        stdout, stderr, status = Helpers.run_cmd('workmux', 'add', branch)
      else
        puts "Running: git worktree add \"#{branch}\""
        stdout, stderr, status = Helpers.run_cmd('git', 'worktree', 'add', branch)
      end

      print stdout unless stdout.empty?
      warn stderr unless stderr.empty?

      exit(status.success? ? 0 : 1)
    end

    private

    def parse_options(argv)
      options = {}

      parser = OptionParser.new do |opts|
        opts.banner = 'Usage: issue "description" [options]'

        opts.on('-t', '--team ID', 'Linear Team ID') { |v| options[:team] = v }
        opts.on('-V', '--version', 'Show version') do
          puts "issue #{VERSION}"
          exit 0
        end
        opts.on('-h', '--help', 'Show help') do
          puts opts
          puts "\nRequires ANTHROPIC_API_KEY and LINEAR_API_KEY environment variables."
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

      options[:team] = resolve_option(options[:team], 'LINEAR_TEAM_ID', Config.team)
      options[:status] = Config.status.to_s.strip
      options[:token] = ENV.fetch('LINEAR_API_KEY', '').strip
      options[:anthropic_key] = ENV.fetch('ANTHROPIC_API_KEY', '').strip

      options
    end

    def resolve_option(value, env_key, config_value = nil)
      v = value.to_s.strip
      return v unless Helpers.blank?(v)

      v = ENV.fetch(env_key, '').strip
      return v unless Helpers.blank?(v)

      config_value.to_s.strip
    end

    def validate!
      require!(:description, 'missing description. Example: issue "Fix webhook timeout"')
      require!(:anthropic_key, 'missing Anthropic API key. Export ANTHROPIC_API_KEY.')
      require!(:team, 'missing team. Use --team, export LINEAR_TEAM_ID, or set team in config.yaml.')
      require!(:token, 'missing Linear token. Export LINEAR_API_KEY.')
    end

    def require!(key, message)
      return unless Helpers.blank?(@options[key])

      warn "Error: #{message}"
      exit 1
    end
  end
end
