# issue

CLI that creates Linear issues using Claude to generate the title and description, then sets up a worktree with [workmux](https://github.com/vnazar/workmux).

Takes a free-text description, sends it to Claude for a well-formed title and description, creates the issue in Linear, and runs `workmux add <branch>` to get the worktree ready.

## Installation

```sh
git clone https://github.com/vnazar/issue.git
cd issue
gem build issue.gemspec
gem install issue-0.1.0.gem
```

## Dependencies

If [workmux](https://github.com/vnazar/workmux) is installed, `issue` uses it to set up the worktree (`workmux add <branch>`). Otherwise it falls back to `git worktree add`.

## Configuration

Requires two environment variables:

| Variable | Description |
|---|---|
| `ANTHROPIC_API_KEY` | Anthropic API key |
| `LINEAR_API_KEY` | Linear API token |

You can also configure defaults in `~/.config/issue/config.yaml`:

```yaml
team: "YOUR_LINEAR_TEAM_ID"
model: "claude-haiku-4-5"
prompt: |
  From the following text, generate an issue for a development team.

  Text:
  {{description}}

  Reply with valid JSON only, no markdown or extra text:
  {"title":"...","description":"..."}

  Rules:
  - title: max 72 characters, clear and specific
  - description: a well-written paragraph explaining the problem or task
```

## Usage

```sh
issue "Fix webhook payment timeout"
```

Options:

```
-t, --team ID     Linear Team ID
-V, --version     Show version
-h, --help        Show help
```

## License

MIT
