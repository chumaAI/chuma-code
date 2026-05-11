# Chuma ⚡

**Universal AI model orchestration harness.**  
Plug any model. Get tool calling, agent loops, chat, and pipelines — regardless of whether the model natively supports them.

```
chuma agent "explain recursion in one paragraph"
chuma agent "write a Python web scraper for Hacker News and test it"
cat report.txt | chuma pipe -t "summarise in 3 bullet points"
```

---

## Why Chuma?

| Feature | Claude Code | Codex CLI | **Chuma** |
|---|---|---|---|
| Works with ANY model | ✗ | ✗ | **✓** |
| Tool calling on any model | ✗ | ✗ | **✓** |
| Zero-config local models (Ollama) | ✗ | ✗ | **✓** |
| Single static binary | ✗ | ✗ | **✓** |
| Unix pipe-friendly | partial | partial | **✓** |
| Written in Rust | ✗ | ✗ | **✓** |

---

## Installation

### Linux / macOS

```bash
curl -sSL https://raw.githubusercontent.com/chumaAI/chuma-code/main/install.sh | bash
```

### Windows (PowerShell)

```powershell
iwr https://raw.githubusercontent.com/chumaAI/chuma-code/main/install.ps1 | iex
```

### Options

```bash
# Pin a version
CHUMA_VERSION=v0.0.3 curl -sSL https://raw.githubusercontent.com/chumaAI/chuma-code/main/install.sh | bash

# Custom install directory
CHUMA_INSTALL_DIR=$HOME/bin curl -sSL https://raw.githubusercontent.com/chumaAI/chuma-code/main/install.sh | bash

# Uninstall
rm "$(which chuma)"

# Build from source
cargo install --git https://github.com/chumaAI/chuma-code
```

---

## Quick Start

```bash
# Set an API key
chuma config set anthropic sk-ant-...
chuma config set openai sk-proj-...
chuma config set groq gsk_...

# Or use Ollama — completely free, no key needed (see Ollama Setup below)

# Set a default provider/model (optional)
chuma config default anthropic claude-sonnet-4-5

# Run a prompt
chuma run "What is the CAP theorem?"
```

---

## Ollama Setup (Free — No API Key)

Chuma works with Ollama out of the box. The recommended default is `gemma4:31b-cloud` — Google's Gemma 4 31B model served free via Ollama's cloud. No local GPU, no download, no API key required.

### 1. Install Ollama

**macOS / Linux**
```bash
curl -fsSL https://ollama.com/install.sh | sh
```

**Windows** — download the installer from https://ollama.com/download

Verify it's running:
```bash
ollama --version
```

### 2. Use gemma4:31b-cloud (recommended)

This tag runs on Ollama's hosted infrastructure — nothing is downloaded to your machine.

```bash
# One-shot
chuma agent "explain the CAP theorem"

# Agent with tools
chuma agent
```

### 3. Set it as your default (optional)

```bash
chuma config default ollama gemma4:31b-cloud
```

After this, plain `chuma agent "..."` uses Gemma 4 automatically.

Or set it in `~/.config/Chuma/config.toml`:

```toml
default_provider = "ollama"
default_model    = "gemma4:31b-cloud"

[providers.ollama]
base_url      = "http://localhost:11434"
default_model = "gemma4:31b-cloud"
```

### 4. Want to run locally instead?

If you have the hardware, pull the full local model (20GB, requires ~24GB RAM/VRAM):

```bash
ollama pull gemma4:31b
chuma agent --provider ollama --model gemma4:31b
```

Lighter local options:

| Model | Size | Best for |
|---|---|---|
| `gemma4:26b` | MoE, only 4B active params | Fast local, near-31B quality |
| `gemma4:e4b` | ~3GB | Laptops, edge devices |
| `gemma3:12b` | 8GB | Creative writing, image tasks |

### Capabilities (gemma4:31b-cloud)

- ✓ Text generation and reasoning
- ✓ Image input (multimodal)
- ✓ Tool calling via Chuma's ToolInjector
- ✓ 256K context window
- ✓ Thinking mode (chain-of-thought)
- ✗ No API key or billing required

> **Note:** `gemma4:31b-cloud` routes to Ollama's hosted inference, which is currently free and generous for personal and dev use. For production workloads, pin to a local model or a provider with a formal SLA.

---

## Commands

```bash
chuma agent "explain the CAP theorem"
chuma agent "write a rename script for .jpg files" --raw
chuma agent -- --provider groq --model llama3-70b-8192 "is Rust better than Go?"
chuma agent -- --system "You are a pirate" "describe the ocean"
chuma agent -- --file prompt.txt
```

### `chuma agent` — Autonomous agent with tools

Runs a ReAct loop.

```bash
chuma agent "create a FastAPI app with a /health endpoint and run it"
chuma agent "find all TODO comments in this repo and summarise them"
chuma agent --max-iter 30 "build and test a complete REST API"
```

**Built-in tools:**

| Tool | What it does |
|---|---|
| `shell` | Run any shell command |
| `read_file` | Read a file from disk |
| `write_file` | Write / create a file |
| `append_file` | Append to a file |
| `list_dir` | List directory contents |
| `fetch_url` | HTTP GET a URL |
| `search_files` | Grep across files |

### `chuma models` / `chuma tools` / `chuma config` / `chuma status`

```bash
chuma models                          # list all available models
chuma models ollama                   # list models available via Ollama
chuma tools list
chuma config show
chuma config edit                     # opens $EDITOR
chuma status                          # health check
```

---

## Configuration

File location: `~/.config/Chuma/config.toml`

```toml
default_provider = "anthropic"
default_model    = "claude-sonnet-4-5"

[providers.anthropic]
api_key = "sk-ant-..."

[providers.openai]
api_key       = "sk-proj-..."
default_model = "gpt-4o"

[providers.groq]
api_key = "gsk_..."

[providers.ollama]
base_url      = "http://localhost:11434"
default_model = "gemma4:31b-cloud"

# Any OpenAI-compatible endpoint
[providers.my_vllm]
base_url = "http://my-server:8080/v1"
api_key  = "optional"

[profiles.coder]
provider      = "anthropic"
model         = "claude-sonnet-4-5"
system_prompt = "You are a senior software engineer. Be concise and correct."
temperature   = 0.3
tools         = ["shell", "read_file", "write_file"]
```

**Environment variable overrides:**

```bash
export CHUMA_PROVIDER=ollama
export CHUMA_MODEL=gemma4:31b-cloud
export ANTHROPIC_API_KEY=sk-ant-...
export OPENAI_API_KEY=sk-proj-...
export GROQ_API_KEY=gsk_...
```

---

## Supported Providers

| Provider | Flag | Notes |
|---|---|---|
| Ollama | `ollama` | **Free. No key.** gemma4:31b-cloud recommended. |
| Anthropic Claude | `anthropic` | Native tools. Best reasoning. |
| OpenAI | `openai` | Native tools. GPT-4o, o1, etc. |
| Groq | `groq` | Native tools. Fastest inference. |
| Together AI | `together` | Open models at scale. |
| Mistral AI | `mistral` | Native tools. EU-based. |
| LM Studio | `lmstudio` | Local. No API key. GUI-based. |
| Any OpenAI-compat | any name | Set `base_url` in config. |

---

## License

[Business Source License 1.1](LICENSE.md)