# Claude Agent SDK Examples

Multi-agent demos using the [Claude Agent SDK](https://github.com/anthropics/claude-agent-sdk-python) with Playwright MCP for browser automation across the zoo.

## Morning Standup Demo

Three AI agents coordinate across six interconnected zoo sites to simulate a developer team's morning routine.

### Prerequisites

- The Zoo running (`npm start` from repo root)
- `ANTHROPIC_API_KEY` environment variable set
- [uv](https://docs.astral.sh/uv/) installed
- Node.js (for Playwright MCP server)

### Run

```bash
cd examples/agent_sdk
uv run morning_standup.py
```

### Environment Variables

| Variable            | Default    | Description         |
| ------------------- | ---------- | ------------------- |
| `ANTHROPIC_API_KEY` | (required) | Anthropic API key   |
| `ZOO_PROXY_PORT`    | `3128`     | Zoo HTTP proxy port |
| `ZOO_AGENT_MODEL`   | `sonnet`   | Claude model to use |
