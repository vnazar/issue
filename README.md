# issue

CLI that creates Linear issues using Claude to generate the title and description, then sets up a worktree with [workmux](https://github.com/vnazar/workmux).

Takes a free-text description, sends it to the Anthropic API for a well-formed title and description, creates the issue in Linear via GraphQL, and runs `workmux add <branch>` to get the worktree ready.

## Installation

```sh
git clone https://github.com/vnazar/issue.git
cd issue
gem build issue.gemspec
gem install issue-0.1.0.gem
```

## Dependencies

Requires [workmux](https://github.com/vnazar/workmux) to be installed and available in your `PATH`. After creating the Linear issue, `issue` calls `workmux add <branch>` to set up the worktree.

## Configuration

Requires three environment variables (or their flag equivalents):

| Variable | Flag | Description |
|---|---|---|
| `ANTHROPIC_API_KEY` | `--anthropic-key` | Anthropic API key |
| `LINEAR_API_KEY` | `--token` | Linear API token |
| `LINEAR_TEAM_ID` | `--team-id` | Linear team ID |

## Usage

```sh
issue "Fix webhook payment timeout"
```

Options:

```
-t, --team-id ID           Linear Team ID
-k, --token TOKEN           Linear API token
-a, --anthropic-key KEY     Anthropic API key
-m, --model MODEL           Anthropic model (default: claude-haiku-4-5)
-V, --version               Show version
-h, --help                  Show help
```

## License

MIT
