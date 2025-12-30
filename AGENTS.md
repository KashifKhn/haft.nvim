# AGENTS.md - Agentic Coding Guidelines for haft.nvim

## Project Overview

Neovim plugin integrating Haft CLI (Spring Boot productivity tool). Written in Lua, follows modern Neovim plugin standards.

## Build/Lint/Test Commands

```bash
# Format code
make format
stylua lua/

# Lint code
make lint
luacheck lua/ --globals vim

# Run all tests
make test
nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

# Run single test file
nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedFile tests/haft/config_spec.lua"

# Run specific test (by pattern)
nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua', sequential = true}" | grep -A 20 "test_name"

# Health check
nvim -c "checkhealth haft"
```

## Code Style Guidelines

### Formatting

- Use **stylua** with config in `.stylua.toml`
- 2 space indentation
- 120 character line width
- No trailing whitespace

### Type Annotations

Use LuaLS annotations for public APIs only:

```lua
---@class HaftConfig
---@field haft_path string
---@field detection HaftDetectionConfig

---@param opts HaftConfig?
---@return boolean
function M.setup(opts)
```

### Comments Policy

- **NO** useless/obvious comments
- **YES** type annotations (`@class`, `@param`, `@return`, `@field`)
- **YES** complex algorithm explanations (rare)
- **YES** non-obvious decision rationale (rare)
- Code must be self-documenting through clear naming

### Naming Conventions

| Type             | Convention        | Example                 |
| ---------------- | ----------------- | ----------------------- |
| Files            | snake_case        | `project_detection.lua` |
| Functions        | snake_case        | `get_project_info()`    |
| Variables        | snake_case        | `project_root`          |
| Constants        | UPPER_SNAKE       | `DEFAULT_TIMEOUT`       |
| Classes (@class) | PascalCase        | `HaftConfig`            |
| Private          | underscore prefix | `_internal_helper()`    |

### Module Pattern

Every Lua file must return a table:

```lua
local M = {}

function M.public_function()
end

local function private_function()
end

return M
```

### Imports

```lua
local Job = require("plenary.job")
local config = require("haft.config")
local notify = require("haft.ui.notify")
```

- One require per line
- Group: external deps first, then internal modules
- Use local variables for all requires

## Error Handling

```lua
local ok, result = pcall(require, "telescope")
if not ok then
  return fallback_behavior()
end

local success, err = pcall(function()
  -- risky operation
end)
if not success then
  notify.error("Operation failed: " .. tostring(err))
  return
end
```

- Use `pcall` for external dependencies
- Never crash the plugin, always graceful degradation
- Show user-friendly error messages via notify

## Testing Standards

### Test File Structure

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
- Mock external dependencies (Haft CLI, filesystem)
- Test edge cases and error conditions

## Commit Message Convention

Follow Conventional Commits:

```
feat(commands): add HaftGenerateResource command
fix(parser): handle empty JSON response
docs(readme): update installation instructions
test(config): add merge behavior tests
refactor(runner): extract async job creation
ci(actions): add Neovim nightly to matrix
chore(deps): update plenary.nvim minimum version
```

Format: `type(scope): description`

Types: `feat`, `fix`, `docs`, `test`, `refactor`, `ci`, `chore`, `perf`, `style`

## Project Structure

```
lua/haft/
├── init.lua          # Entry point, setup(), public API
├── config.lua        # Configuration defaults and merging
├── commands.lua      # Vim user command definitions
├── api.lua           # Public Lua API functions
├── runner.lua        # Async CLI execution (plenary.job)
├── parser.lua        # JSON output parsing
├── detection.lua     # Project type detection
├── health.lua        # :checkhealth implementation
├── ui/
│   ├── float.lua     # Floating window management
│   ├── notify.lua    # Notification system
│   ├── terminal.lua  # Terminal buffer management
│   └── input.lua     # Input prompts
└── telescope/
    ├── init.lua      # Extension registration
    └── pickers/      # Individual picker implementations
```

## Key Patterns

### Async Execution

```lua
local Job = require("plenary.job")

Job:new({
  command = "haft",
  args = { "info", "--json" },
  on_exit = vim.schedule_wrap(function(j, return_val)
    local output = table.concat(j:result(), "\n")
    callback(output, return_val)
  end),
}):start()
```

### Configuration Access

```lua
local config = require("haft.config")
local haft_path = config.get().haft_path
```

### User Notifications

```lua
local notify = require("haft.ui.notify")
notify.info("Files generated successfully")
notify.error("Haft CLI not found")
notify.warn("Not in a Haft project")
```

## Do NOT

- Add useless comments explaining obvious code
- Use `vim.fn.system()` for long-running commands (blocks UI)
- Create default keybindings (user configures their own)
- Commit without running `make lint` and `make test`
- Use global variables (always local)
- Ignore error handling

## Do

- Write self-documenting code with clear names
- Add type annotations for public functions
- Run tests before committing
- Follow single responsibility principle
- Use async patterns for CLI calls
- Provide graceful fallbacks (Telescope -> vim.ui.select)
- Make everything configurable
