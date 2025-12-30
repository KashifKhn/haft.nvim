local config = require("haft.config")

local M = {}

M._initialized = false

---@param opts HaftConfig?
function M.setup(opts)
  if M._initialized then
    return
  end

  config.setup(opts)
  M._initialized = true
end

---@return boolean
function M.is_haft_project()
  local detection = require("haft.detection")
  return detection.is_haft_project()
end

---@return table?
function M.get_project_info()
  local detection = require("haft.detection")
  return detection.get_project_info()
end

return M
