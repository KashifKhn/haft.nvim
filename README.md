# haft.nvim

[![Neovim](https://img.shields.io/badge/Neovim-%3E%3D0.9.0-green?style=for-the-badge&logo=neovim)](https://neovim.io)
[![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet?style=for-the-badge&logo=lua)](https://lua.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

Neovim plugin for [Haft CLI](https://github.com/KashifKhn/haft) - The Spring Boot productivity tool.

## Features

- Full integration with all Haft CLI commands
- Telescope pickers for interactive selection
- Floating windows for detailed output
- Async command execution (non-blocking)
- Auto-detection of Haft/Spring Boot projects
- Fully configurable with no default keybindings
- Graceful fallbacks (Telescope -> vim.ui.select)

## Requirements

### Required

| Dependency | Version | Purpose |
|------------|---------|---------|
| Neovim | >= 0.9.0 | Modern Lua API |
| [Haft CLI](https://github.com/KashifKhn/haft) | >= 0.1.11 | Spring Boot CLI |
| [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) | latest | Async utilities |

### Optional (Recommended)

| Dependency | Purpose |
|------------|---------|
| [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | Interactive pickers |
| [noice.nvim](https://github.com/folke/noice.nvim) | Enhanced notifications |
| [nui.nvim](https://github.com/MunifTanjim/nui.nvim) | UI components |
| [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) | File icons |

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim) (Recommended)

```lua
{
  "KashifKhn/haft.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim", -- optional but recommended
  },
  cmd = {
    "HaftInfo", "HaftRoutes", "HaftStats",
    "HaftAdd", "HaftRemove",
    "HaftGenerate", "HaftGenerateResource", "HaftGenerateController",
    "HaftGenerateService", "HaftGenerateRepository", "HaftGenerateEntity",
    "HaftGenerateDto", "HaftGenerateException", "HaftGenerateConfig",
    "HaftGenerateSecurity",
    "HaftDevBuild", "HaftDevTest", "HaftDevServe", "HaftDevRestart",
    "HaftDevClean", "HaftDevToggle",
  },
  opts = {},
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "KashifKhn/haft.nvim",
  requires = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    require("haft").setup()
  end,
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'KashifKhn/haft.nvim'

lua require("haft").setup()
```

## Configuration

### Default Configuration

```lua
require("haft").setup({
  -- Path to haft binary (auto-detected if in PATH)
  haft_path = "haft",

  -- Auto-detection settings
  detection = {
    enabled = true,
    patterns = { ".haft.yaml", "pom.xml", "build.gradle", "build.gradle.kts" },
  },

  -- Notification settings
  notifications = {
    enabled = true,
    level = "info",    -- "debug", "info", "warn", "error"
    timeout = 3000,
  },

  -- Floating window settings
  float = {
    border = "rounded",   -- "none", "single", "double", "rounded", "solid", "shadow"
    width = 0.8,          -- 0-1 for percentage, or integer for fixed
    height = 0.8,
    title_pos = "center", -- "left", "center", "right"
  },

  -- Picker settings
  picker = {
    provider = "auto",    -- "auto", "telescope", "native"
    telescope = {
      theme = "dropdown", -- "dropdown", "cursor", "ivy", or nil
      layout_config = { width = 0.8, height = 0.6 },
    },
  },

  -- Auto-open generated files
  auto_open = {
    enabled = true,
    strategy = "first",   -- "first", "all", "none"
  },

  -- Quickfix integration
  quickfix = {
    enabled = true,
    auto_open = false,
  },

  -- Terminal settings
  terminal = {
    type = "auto",        -- "auto", "float", "split", "vsplit", "tab"
    float = {
      border = "rounded",
      width = 0.8,
      height = 0.8,
    },
    split = {
      size = 15,
      position = "below", -- "below", "above"
    },
    persist = true,       -- Keep terminal buffer alive
    auto_close = false,   -- Close on success
  },

  -- Dev settings
  dev = {
    restart_on_save = false,
    save_patterns = { "*.java", "*.kt", "*.xml", "*.yaml", "*.yml", "*.properties" },
  },

  -- Command settings
  commands = {
    generate = {
      refresh = false,    -- Force re-detection by default
    },
  },

  -- Keymaps (empty by default - user configures)
  keymaps = {},
})
```

### Picker Provider

| Value | Behavior |
|-------|----------|
| `"auto"` | Use Telescope if available, fallback to vim.ui.select |
| `"telescope"` | Force Telescope, error if unavailable |
| `"native"` | Always use vim.ui.select |

### Terminal Type

| Value | Behavior |
|-------|----------|
| `"auto"` | Prefer split, fallback to float |
| `"float"` | Floating window |
| `"split"` | Horizontal split at bottom |
| `"vsplit"` | Vertical split at right |
| `"tab"` | New tab |

## Commands

### Project Information

| Command | Description |
|---------|-------------|
| `:HaftInfo` | Show project information in floating window |
| `:HaftRoutes` | Show API routes in floating window |
| `:HaftStats` | Show code statistics in floating window |

### Dependency Management

| Command | Description |
|---------|-------------|
| `:HaftAdd [dep...]` | Add dependencies (picker if no args) |
| `:HaftRemove [dep...]` | Remove dependencies (picker if no args) |

### Code Generation

| Command | Description |
|---------|-------------|
| `:HaftGenerate` | Open component type picker |
| `:HaftGenerateResource [name]` | Generate complete CRUD resource |
| `:HaftGenerateController [name]` | Generate REST controller |
| `:HaftGenerateService [name]` | Generate service layer |
| `:HaftGenerateRepository [name]` | Generate JPA repository |
| `:HaftGenerateEntity [name]` | Generate JPA entity |
| `:HaftGenerateDto [name]` | Generate Request/Response DTOs |
| `:HaftGenerateException` | Generate exception handler (picker) |
| `:HaftGenerateConfig` | Generate config classes (picker) |
| `:HaftGenerateSecurity` | Generate security setup (picker) |

### Development

| Command | Description |
|---------|-------------|
| `:HaftDevBuild` | Build project |
| `:HaftDevTest` | Run tests |
| `:HaftDevServe` | Start dev server with hot-reload |
| `:HaftDevRestart` | Trigger restart of running server |
| `:HaftDevClean` | Clean build artifacts |
| `:HaftDevToggle` | Toggle terminal visibility |

## Telescope Extension

```vim
:Telescope haft dependencies    " Add dependencies picker
:Telescope haft remove          " Remove dependencies picker
:Telescope haft generate        " Component type picker
:Telescope haft exceptions      " Exception types picker
:Telescope haft configs         " Config classes picker
:Telescope haft security        " Security types picker
```

Or via Lua:

```lua
require("telescope").extensions.haft.dependencies()
require("telescope").extensions.haft.remove()
require("telescope").extensions.haft.generate()
```

## Keybindings

No default keybindings are provided. Configure your own:

```lua
-- Suggested keybindings
vim.keymap.set("n", "<leader>hi", "<cmd>HaftInfo<cr>", { desc = "Haft: Info" })
vim.keymap.set("n", "<leader>hr", "<cmd>HaftRoutes<cr>", { desc = "Haft: Routes" })
vim.keymap.set("n", "<leader>hs", "<cmd>HaftStats<cr>", { desc = "Haft: Stats" })

vim.keymap.set("n", "<leader>ha", "<cmd>HaftAdd<cr>", { desc = "Haft: Add dependency" })
vim.keymap.set("n", "<leader>hR", "<cmd>HaftRemove<cr>", { desc = "Haft: Remove dependency" })

vim.keymap.set("n", "<leader>hg", "<cmd>HaftGenerate<cr>", { desc = "Haft: Generate" })
vim.keymap.set("n", "<leader>hG", "<cmd>HaftGenerateResource<cr>", { desc = "Haft: Generate resource" })

vim.keymap.set("n", "<leader>hdb", "<cmd>HaftDevBuild<cr>", { desc = "Haft: Build" })
vim.keymap.set("n", "<leader>hdt", "<cmd>HaftDevTest<cr>", { desc = "Haft: Test" })
vim.keymap.set("n", "<leader>hds", "<cmd>HaftDevServe<cr>", { desc = "Haft: Serve" })
vim.keymap.set("n", "<leader>hdr", "<cmd>HaftDevRestart<cr>", { desc = "Haft: Restart" })
vim.keymap.set("n", "<leader>hdc", "<cmd>HaftDevClean<cr>", { desc = "Haft: Clean" })
vim.keymap.set("n", "<leader>hdT", "<cmd>HaftDevToggle<cr>", { desc = "Haft: Toggle terminal" })
```

### With which-key.nvim

```lua
local wk = require("which-key")
wk.add({
  { "<leader>h", group = "Haft" },
  { "<leader>hd", group = "Dev" },
})
```

## Lua API

```lua
local haft = require("haft")

-- Setup (required)
haft.setup(opts)

-- Project detection
haft.is_haft_project()      -- boolean
haft.get_project_info()     -- table or nil

-- Commands (programmatic)
haft.info()
haft.routes()
haft.stats()
haft.add(dependencies)
haft.remove(dependencies)
haft.generate(type, name)
haft.generate_resource(name)
haft.generate_controller(name)
haft.generate_service(name)
haft.generate_repository(name)
haft.generate_entity(name)
haft.generate_dto(name)
haft.generate_exception()
haft.generate_config()
haft.generate_security()
haft.dev_build()
haft.dev_test()
haft.dev_serve()
haft.dev_restart()
haft.dev_clean()
haft.dev_toggle()
```

## User Events

```lua
vim.api.nvim_create_autocmd("User", {
  pattern = "HaftProjectDetected",
  callback = function(ev)
    print("Haft project detected: " .. ev.data.name)
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "HaftFilesGenerated",
  callback = function(ev)
    print("Generated " .. #ev.data.files .. " files")
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "HaftCommandComplete",
  callback = function(ev)
    print("Command completed: " .. ev.data.command)
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "HaftCommandError",
  callback = function(ev)
    print("Command failed: " .. ev.data.error)
  end,
})
```

## Health Check

Run `:checkhealth haft` to verify your setup.

```
haft: require("haft.health").check()

haft.nvim ~
- OK Neovim >= 0.9.0
- OK Haft CLI found: haft version v0.1.11
- OK plenary.nvim installed
- OK telescope.nvim installed (optional)
- WARNING noice.nvim not found (optional)
- INFO No Haft project in current directory
```

## Troubleshooting

### Haft CLI not found

Ensure Haft CLI is installed and in your PATH:

```bash
haft --version
```

Or set custom path in config:

```lua
require("haft").setup({
  haft_path = "/path/to/haft",
})
```

### Telescope not working

If Telescope pickers don't open, check:

1. Telescope is installed: `:Telescope`
2. Extension is loaded: `:Telescope haft`
3. Or switch to native picker:

```lua
require("haft").setup({
  picker = { provider = "native" },
})
```

### Commands not working in non-Haft projects

Most commands require being in a Haft/Spring Boot project directory. Check:

1. Run `:HaftInfo` to see if project is detected
2. Look for `pom.xml`, `build.gradle`, or `.haft.yaml` in project root

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Related

- [Haft CLI](https://github.com/KashifKhn/haft) - The CLI this plugin integrates with
- [Haft Documentation](https://kashifkhn.github.io/haft) - Full CLI documentation
