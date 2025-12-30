local config = require("haft.config")

local M = {}

M._pickers = {}

function M.is_telescope_available()
  local ok = pcall(require, "telescope")
  return ok
end

function M.get_provider()
  local cfg = config.get()
  local provider = cfg.picker.provider

  if provider == "telescope" then
    if not M.is_telescope_available() then
      local notify = require("haft.ui.notify")
      notify.error("Telescope is required but not installed")
      return nil
    end
    return "telescope"
  elseif provider == "native" then
    return "native"
  else
    if M.is_telescope_available() then
      return "telescope"
    end
    return "native"
  end
end

function M.register_picker(name, picker_fn)
  M._pickers[name] = picker_fn
end

function M.get_picker(name)
  return M._pickers[name]
end

function M.setup()
  local ok, _ = pcall(require, "telescope")
  if not ok then
    return
  end

  require("haft.telescope.pickers.dependencies")
end

return M
