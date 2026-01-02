local config = require("haft.config")

local M = {}

M._initialized = false

---@param opts HaftConfig?
function M.setup(opts)
  if M._initialized then
    return
  end

  config.setup(opts)

  local commands = require("haft.commands")
  commands.setup()

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

function M.info()
  local api = require("haft.api")
  api.info()
end

function M.routes()
  local api = require("haft.api")
  api.routes()
end

function M.stats()
  local api = require("haft.api")
  api.stats()
end

---@param name string?
function M.generate_resource(name)
  local api = require("haft.api")
  api.generate_resource(name)
end

---@param name string?
function M.generate_controller(name)
  local api = require("haft.api")
  api.generate_controller(name)
end

---@param name string?
function M.generate_service(name)
  local api = require("haft.api")
  api.generate_service(name)
end

---@param name string?
function M.generate_repository(name)
  local api = require("haft.api")
  api.generate_repository(name)
end

---@param name string?
function M.generate_entity(name)
  local api = require("haft.api")
  api.generate_entity(name)
end

---@param name string?
function M.generate_dto(name)
  local api = require("haft.api")
  api.generate_dto(name)
end

---@param deps string[]?
function M.add(deps)
  local api = require("haft.api")
  api.add(deps)
end

---@param deps string[]?
function M.remove(deps)
  local api = require("haft.api")
  api.remove(deps)
end

return M
