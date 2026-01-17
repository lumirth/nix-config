# Mise Example Configuration

This document provides a template for using mise in projects.

## Important: Nix for Global, Mise for Per-Project

**Your global runtimes come from Nix (home.nix):**
- `node` (v22), `python3` (v3.13), `go`, `ruby` (v3.3), `rustup`, `uv`

**Use mise ONLY for per-project version overrides.**

Do NOT run `mise use --global` for languages already installed via Nix.

## Basic mise.toml

```toml
# mise.toml - Per-project environment configuration
# Only use when you need DIFFERENT versions than your Nix globals

[tools]
# =============================================================================
# Version overrides (only when project needs different than Nix global)
# =============================================================================
# Your Nix globals: node@22, python@3.13, go, ruby@3.3, rust (via rustup)
# Only specify here if you need DIFFERENT versions:
node = "18.19.0"      # Example: legacy project needs Node 18
python = "3.11"       # Example: project needs Python 3.11

# =============================================================================
# Nix backend (reproducible system deps)
# Use these for databases, complex CLI tools with C dependencies
# =============================================================================
"nix:postgresql" = "16"
"nix:redis" = "7"
# "nix:ffmpeg" = "6"
# "nix:imagemagick" = "latest"

[env]
# =============================================================================
# Environment variables
# =============================================================================
DATABASE_URL = "postgresql://localhost:5432/myapp"
REDIS_URL = "redis://localhost:6379"

# Auto-create Python virtual environment
_.python.venv = { path = ".venv", create = true }

[tasks]
# =============================================================================
# Project tasks (like npm scripts or make targets)
# =============================================================================
dev = "npm run dev"
test = "pytest"
lint = "npm run lint && ruff check ."
build = "npm run build"

# Service management (if using nix: backends for databases)
"db:start" = "pg_ctl start -D .postgres"
"db:stop" = "pg_ctl stop -D .postgres"
"db:init" = "initdb -D .postgres && pg_ctl start -D .postgres && createdb myapp"

"redis:start" = "redis-server --daemonize yes"
"redis:stop" = "redis-cli shutdown"

# Combined commands
"services:up" = { depends = ["db:start", "redis:start"] }
"services:down" = { depends = ["db:stop", "redis:stop"] }
```

## When to Use Each Backend

### Don't Override Unless Needed

If your project works with the Nix global versions, you don't need mise.toml at all!

Only create mise.toml when:
1. Project requires a **specific older version** (legacy compatibility)
2. Project needs **databases or system tools** (use `nix:` backend)
3. Project has **environment variables or tasks** to define

### Native Backends (for version overrides)

Use for language runtimes and simple tools:

```toml
[tools]
node = "22"           # JavaScript/TypeScript
python = "3.13"       # Python
go = "1.22"           # Go
rust = "stable"       # Rust
ruby = "3.3"          # Ruby
java = "21"           # Java (via SDKMAN backend)
```

**Why native:** Prebuilt binaries download in seconds. No Nix evaluation overhead.

### Nix Backend

Use for system dependencies and tools with complex C library requirements:

```toml
[tools]
"nix:postgresql" = "16"     # Database
"nix:redis" = "7"           # Cache
"nix:ffmpeg" = "6"          # Video processing
"nix:imagemagick" = "7"     # Image processing
"nix:pandoc" = "latest"     # Document conversion
"nix:graphviz" = "latest"   # Graph visualization
```

**Why Nix:** These tools often depend on system libraries (libssl, libc, etc.). Nix bundles everything, ensuring they work identically on any machine.

## Quick Start

1. Create `mise.toml` in your project root
2. Run `mise install` to install all tools
3. Tools are now available in your shell when in this directory

```bash
cd ~/my-project
mise install
node --version  # Uses project-specific version
```

## Lockfile

Mise creates a `mise.lock` file with exact versions. **Commit this file** to ensure everyone on the team gets identical versions:

```bash
git add mise.toml mise.lock
git commit -m "Add mise configuration"
```

## Environment Variables

### Static Values

```toml
[env]
API_URL = "https://api.example.com"
DEBUG = "true"
```

### Dynamic Values

```toml
[env]
# Use command output
PROJECT_ROOT = "{{cwd}}"
GIT_BRANCH = "{{exec(command='git branch --show-current')}}"

# Reference other env vars
FULL_DATABASE_URL = "{{env.DATABASE_URL}}?sslmode=require"
```

### File-Based Secrets

```toml
[env]
# Load from .env file (gitignored)
_.file = ".env"

# Or specific dotenv files
_.file = [".env", ".env.local"]
```

## Tasks

### Simple Commands

```toml
[tasks]
dev = "npm run dev"
test = "pytest -v"
```

### With Dependencies

```toml
[tasks]
"test:unit" = "pytest tests/unit"
"test:integration" = "pytest tests/integration"
"test:all" = { depends = ["test:unit", "test:integration"] }
```

### With Environment

```toml
[tasks.test]
run = "pytest"
env = { TESTING = "true", DATABASE_URL = "sqlite:///:memory:" }
```

## Docker Compose Integration

For services that are easier to run in containers:

```toml
[tasks]
"docker:up" = "docker-compose up -d"
"docker:down" = "docker-compose down"
"docker:logs" = "docker-compose logs -f"
```

## Migration from devenv

If migrating from a `devenv.nix` file:

| devenv.nix | mise.toml |
|------------|-----------|
| `languages.python.enable = true` | `python = "3.12"` |
| `languages.python.package = pkgs.python311` | `python = "3.11"` |
| `packages = [ pkgs.postgresql ]` | `"nix:postgresql" = "16"` |
| `env.DATABASE_URL = "..."` | `[env] DATABASE_URL = "..."` |
| `scripts.dev.exec = "npm run dev"` | `[tasks] dev = "npm run dev"` |
| `services.postgres.enable = true` | Use docker-compose or manual pg_ctl |

## More Information

- [mise documentation](https://mise.jdx.dev/)
- [mise GitHub](https://github.com/jdx/mise)
- [mise.toml reference](https://mise.jdx.dev/configuration.html)

---

## Advanced: Mise-First, Nix-Powered Architecture

For projects needing heavy infrastructure (databases, complex services), use mise as the entry point that delegates to Nix.

### The Mental Model

```
Developer runs: mise run dev
        │
        ▼
┌─────────────────────────────────────┐
│  mise.toml (fast, simple)           │
│  - node@18 (native, instant)        │
│  - python@3.11 (native, instant)    │
│  - [tasks.dev] calls nix run .#dev  │
└─────────────────────────────────────┘
        │
        ▼ (only when needed)
┌─────────────────────────────────────┐
│  flake.nix (heavy infrastructure)   │
│  - Postgres                         │
│  - Redis                            │
│  - Complex services                 │
└─────────────────────────────────────┘
```

### Example: Full-Stack Project

**mise.toml** (your entry point):
```toml
[tools]
node = "20"
python = "3.12"

[env]
DATABASE_URL = "postgresql://localhost:5432/myapp"

[tasks]
# Delegate infrastructure to Nix
"services:up" = "docker-compose up -d"  # Or: "nix run .#services"
"services:down" = "docker-compose down"

# Dev task depends on services
dev = { run = "npm run dev", depends = ["services:up"] }
test = "npm test"
```

**docker-compose.yml** (or use a flake.nix for pure Nix):
```yaml
services:
  postgres:
    image: postgres:16
    ports: ["5432:5432"]
    environment:
      POSTGRES_DB: myapp
      POSTGRES_HOST_AUTH_METHOD: trust
  redis:
    image: redis:7
    ports: ["6379:6379"]
```

### Why This Works Well

1. **Zero shell latency** - You're in your normal shell, mise provides Node/Python instantly
2. **On-demand infrastructure** - Only pay the docker/nix cost when running `mise run dev`
3. **Clear boundaries** - mise handles code tools, docker/nix handles services
4. **Single entry point** - Team only needs to know `mise run dev`

### Alternative: Pure Nix for Services

If you prefer Nix over Docker for services:

```toml
[tasks]
"services:up" = "nix run .#dev-services"
```

With a `flake.nix` that defines those services. But docker-compose is simpler for most cases.

