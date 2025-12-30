---@class HaftDetectionConfig
---@field enabled boolean
---@field patterns string[]

---@class HaftNotificationsConfig
---@field enabled boolean
---@field level string
---@field timeout number

---@class HaftFloatConfig
---@field border string
---@field width number
---@field height number
---@field title_pos string

---@class HaftTelescopeConfig
---@field theme string?
---@field layout_config table

---@class HaftPickerConfig
---@field provider string
---@field telescope HaftTelescopeConfig

---@class HaftAutoOpenConfig
---@field enabled boolean
---@field strategy string

---@class HaftQuickfixConfig
---@field enabled boolean
---@field auto_open boolean

---@class HaftTerminalFloatConfig
---@field border string
---@field width number
---@field height number

---@class HaftTerminalSplitConfig
---@field size number
---@field position string

---@class HaftTerminalConfig
---@field type string
---@field float HaftTerminalFloatConfig
---@field split HaftTerminalSplitConfig
---@field persist boolean
---@field auto_close boolean

---@class HaftDevConfig
---@field restart_on_save boolean
---@field save_patterns string[]

---@class HaftGenerateCommandConfig
---@field refresh boolean

---@class HaftCommandsConfig
---@field generate HaftGenerateCommandConfig

---@class HaftConfig
---@field haft_path string
---@field detection HaftDetectionConfig
---@field notifications HaftNotificationsConfig
---@field float HaftFloatConfig
---@field picker HaftPickerConfig
---@field auto_open HaftAutoOpenConfig
---@field quickfix HaftQuickfixConfig
---@field terminal HaftTerminalConfig
---@field dev HaftDevConfig
---@field commands HaftCommandsConfig
---@field keymaps table

local M = {}

---@type HaftConfig
local defaults = {
  haft_path = "haft",

  detection = {
    enabled = true,
    patterns = { ".haft.yaml", "pom.xml", "build.gradle", "build.gradle.kts" },
  },

  notifications = {
    enabled = true,
    level = "info",
    timeout = 3000,
  },

  float = {
    border = "rounded",
    width = 0.8,
    height = 0.8,
    title_pos = "center",
  },

  picker = {
    provider = "auto",
    telescope = {
      theme = "dropdown",
      layout_config = { width = 0.8, height = 0.6 },
    },
  },

  auto_open = {
    enabled = true,
    strategy = "first",
  },

  quickfix = {
    enabled = true,
    auto_open = false,
  },

  terminal = {
    type = "auto",
    float = {
      border = "rounded",
      width = 0.8,
      height = 0.8,
    },
    split = {
      size = 15,
      position = "below",
    },
    persist = true,
    auto_close = false,
  },

  dev = {
    restart_on_save = false,
    save_patterns = { "*.java", "*.kt", "*.xml", "*.yaml", "*.yml", "*.properties" },
  },

  commands = {
    generate = {
      refresh = false,
    },
  },

  keymaps = {},
}

---@type HaftConfig?
M.options = nil

local islist = vim.islist or vim.tbl_islist

---@param tbl1 table
---@param tbl2 table
---@return table
local function deep_merge(tbl1, tbl2)
  local result = vim.deepcopy(tbl1)
  for key, value in pairs(tbl2) do
    if type(value) == "table" and type(result[key]) == "table" and not islist(value) then
      result[key] = deep_merge(result[key], value)
    else
      result[key] = value
    end
  end
  return result
end

---@param opts HaftConfig?
function M.setup(opts)
  opts = opts or {}
  M.options = deep_merge(defaults, opts)
end

---@return HaftConfig
function M.get()
  if not M.options then
    M.setup({})
  end
  return M.options
end

function M.reset()
  M.options = nil
end

---@return HaftConfig
function M.get_defaults()
  return vim.deepcopy(defaults)
end

return M
