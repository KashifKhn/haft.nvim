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

  local api = require("haft.api")
  api._init_auto_restart()

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

---@param opts table?
function M.generate_exception(opts)
  local api = require("haft.api")
  api.generate_exception(opts)
end

---@param opts table?
function M.generate_config(opts)
  local api = require("haft.api")
  api.generate_config(opts)
end

---@param opts table?
function M.generate_security(opts)
  local api = require("haft.api")
  api.generate_security(opts)
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

function M.serve()
  local api = require("haft.api")
  api.serve()
end

function M.serve_stop()
  local api = require("haft.api")
  api.serve_stop()
end

function M.serve_toggle()
  local api = require("haft.api")
  api.serve_toggle()
end

function M.restart()
  local api = require("haft.api")
  api.restart()
end

function M.build()
  local api = require("haft.api")
  api.build()
end

function M.test()
  local api = require("haft.api")
  api.test()
end

function M.clean()
  local api = require("haft.api")
  api.clean()
end

function M.deps()
  local api = require("haft.api")
  api.deps()
end

function M.outdated()
  local api = require("haft.api")
  api.outdated()
end

function M.enable_auto_restart()
  local api = require("haft.api")
  api.enable_auto_restart()
end

function M.disable_auto_restart()
  local api = require("haft.api")
  api.disable_auto_restart()
end

function M.toggle_auto_restart()
  local api = require("haft.api")
  api.toggle_auto_restart()
end

---@return boolean
function M.is_auto_restart_enabled()
  local api = require("haft.api")
  return api.is_auto_restart_enabled()
end

---@param opts table?
function M.init(opts)
  local api = require("haft.api")
  api.init(opts)
end

function M.init_tui()
  local api = require("haft.api")
  api.init_tui()
end

function M.init_wizard()
  local api = require("haft.api")
  api.init_wizard()
end

---@param opts table?
function M.init_quick(opts)
  local api = require("haft.api")
  api.init_quick(opts)
end

return M
