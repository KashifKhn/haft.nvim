# Contributing to haft.nvim

Thank you for your interest in contributing to haft.nvim! This document provides guidelines and instructions for contributors.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Code Style](#code-style)
- [Testing](#testing)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Documentation](#documentation)

## Code of Conduct

Be respectful and inclusive. We welcome contributions from everyone.

## Getting Started

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/haft.nvim.git
   cd haft.nvim
   ```
3. Add upstream remote:
   ```bash
   git remote add upstream https://github.com/KashifKhn/haft.nvim.git
   ```

## Development Setup

### Prerequisites

- Neovim >= 0.9.0
- Haft CLI >= 0.1.11
- stylua (Lua formatter)
- luacheck (Lua linter)

### Install Development Tools

```bash
# Install stylua
cargo install stylua
# or
brew install stylua

# Install luacheck
luarocks install luacheck
# or
brew install luacheck
```

### Install Dependencies

Install plugin dependencies for testing:

```bash
# Clone plenary.nvim (required)
git clone https://github.com/nvim-lua/plenary.nvim ~/.local/share/nvim/site/pack/vendor/start/plenary.nvim

# Clone telescope.nvim (optional but recommended)
git clone https://github.com/nvim-telescope/telescope.nvim ~/.local/share/nvim/site/pack/vendor/start/telescope.nvim
```

### Running the Plugin Locally

Create a test configuration:

```lua
-- test-init.lua
vim.opt.rtp:prepend(".")
vim.opt.rtp:prepend("~/.local/share/nvim/site/pack/vendor/start/plenary.nvim")
vim.opt.rtp:prepend("~/.local/share/nvim/site/pack/vendor/start/telescope.nvim")

require("haft").setup()
```

Run Neovim with the test config:

```bash
nvim -u test-init.lua
```

## Project Structure

```
haft.nvim/
├── lua/haft/
│   ├── init.lua          # Main entry, setup(), public API
│   ├── config.lua        # Configuration handling
│   ├── commands.lua      # Vim command definitions
│   ├── api.lua           # Public API functions
│   ├── runner.lua        # Async command execution
│   ├── parser.lua        # JSON parsing
│   ├── detection.lua     # Project detection
│   ├── health.lua        # Health check
│   ├── ui/
│   │   ├── float.lua     # Floating windows
│   │   ├── notify.lua    # Notifications
│   │   ├── terminal.lua  # Terminal management
│   │   └── input.lua     # Input prompts
│   └── telescope/
│       ├── init.lua      # Extension registration
│       └── pickers/      # Picker implementations
├── plugin/
│   └── haft.lua          # Plugin entry point
├── tests/
│   ├── minimal_init.lua  # Test configuration
│   └── haft/             # Test files
└── doc/
    └── haft.txt          # Vimdoc
```

## Code Style

### Formatting

Use stylua for formatting:

```bash
make format
# or
stylua lua/
```

Configuration is in `.stylua.toml`:
- 2 space indentation
- 120 character line width

### Linting

Use luacheck for linting:

```bash
make lint
# or
luacheck lua/ --globals vim
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Files | snake_case | `project_detection.lua` |
| Functions | snake_case | `get_project_info()` |
| Variables | snake_case | `project_root` |
| Constants | UPPER_SNAKE | `DEFAULT_TIMEOUT` |
| Classes (@class) | PascalCase | `HaftConfig` |
| Private functions | underscore prefix | `_internal_helper()` |

### Type Annotations

Use LuaLS annotations for public APIs:

```lua
---@class HaftConfig
---@field haft_path string

---@param opts HaftConfig?
---@return boolean
function M.setup(opts)
```

### Module Pattern

Every file must return a table:

```lua
local M = {}

function M.public_function()
end

local function private_function()
end

return M
```

### Comments Policy

- **NO** useless/obvious comments
- **YES** type annotations
- **YES** complex algorithm explanations (rare)
- Code should be self-documenting

### Imports

```lua
-- External dependencies first
local Job = require("plenary.job")

-- Internal modules second
local config = require("haft.config")
local notify = require("haft.ui.notify")
```

## Testing

### Running Tests

```bash
# Run all tests
make test

# Run single test file
nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedFile tests/haft/config_spec.lua"
```

### Writing Tests

Test files go in `tests/haft/` with `_spec.lua` suffix:

```lua
describe("haft.config", function()
  local config = require("haft.config")

  before_each(function()
    config.reset()
  end)

  describe("setup", function()
    it("uses defaults when no opts provided", function()
      config.setup({})
      assert.equals("haft", config.options.haft_path)
    end)

    it("merges user options with defaults", function()
      config.setup({ haft_path = "/custom/haft" })
      assert.equals("/custom/haft", config.options.haft_path)
    end)
  end)
end)
```

### Test Requirements

- Unit tests for: config, parser, detection, runner
- Integration tests for: command flow, UI components
- Mock external dependencies
- Test edge cases and error conditions

## Commit Guidelines

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(commands): add HaftGenerateResource command
fix(parser): handle empty JSON response
docs(readme): update installation instructions
test(config): add merge behavior tests
refactor(runner): extract async job creation
ci(actions): add Neovim nightly to matrix
chore(deps): update plenary.nvim minimum version
```

### Format

```
type(scope): description

[optional body]

[optional footer]
```

### Types

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation |
| `test` | Tests |
| `refactor` | Code refactoring |
| `ci` | CI/CD changes |
| `chore` | Maintenance |
| `perf` | Performance |
| `style` | Formatting |

### Scopes

- `commands` - User commands
- `config` - Configuration
- `api` - Public API
- `runner` - Command execution
- `parser` - JSON parsing
- `detection` - Project detection
- `health` - Health check
- `ui` - UI components
- `telescope` - Telescope integration
- `readme` - README
- `actions` - GitHub Actions

## Pull Request Process

1. **Create a branch**
   ```bash
   git checkout -b feat/my-feature
   ```

2. **Make changes**
   - Follow code style guidelines
   - Add tests for new functionality
   - Update documentation if needed

3. **Run checks**
   ```bash
   make format
   make lint
   make test
   ```

4. **Commit changes**
   ```bash
   git add .
   git commit -m "feat(scope): description"
   ```

5. **Push and create PR**
   ```bash
   git push origin feat/my-feature
   ```

6. **PR Description**
   - Describe what the PR does
   - Link related issues
   - Include screenshots if UI changes

7. **Review Process**
   - Address reviewer feedback
   - Keep commits clean (squash if needed)
   - Ensure CI passes

## Documentation

### README.md

Update README.md for:
- New features
- New configuration options
- New commands

### Vimdoc (doc/haft.txt)

Update vimdoc for:
- New commands (add to |haft-commands|)
- New API functions (add to |haft-api|)
- New configuration options (add to |haft-configuration|)

Vimdoc format:
```
                                                                *:HaftNewCommand*
:HaftNewCommand [args]~
    Description of what the command does.
    
    Example:~
>vim
        :HaftNewCommand foo
<
```

### Code Comments

- Add type annotations for public functions
- Document non-obvious behavior
- Avoid redundant comments

## Need Help?

- Open an issue for bugs or feature requests
- Start a discussion for questions
- Check existing issues before creating new ones

Thank you for contributing!
