local config = require("haft.config")
local parser = require("haft.parser")

local M = {}

---@class HaftRunnerResult
---@field success boolean
---@field output string
---@field code number
---@field data table?

---@class HaftRunnerOpts
---@field args string[]
---@field cwd string?
---@field json boolean?
---@field on_success fun(result: HaftRunnerResult)?
---@field on_error fun(result: HaftRunnerResult)?
---@field on_complete fun(result: HaftRunnerResult)?

---@param opts HaftRunnerOpts
---@return nil
function M.run(opts)
  local ok, Job = pcall(require, "plenary.job")
  if not ok then
    local notify = require("haft.ui.notify")
    notify.error("plenary.nvim is required for haft.nvim")
    return
  end

  local cfg = config.get()
  local args = opts.args or {}

  if opts.json then
    table.insert(args, "--json")
    table.insert(args, "--no-color")
  end

  local stdout_results = {}
  local stderr_results = {}

  Job:new({
    command = cfg.haft_path,
    args = args,
    cwd = opts.cwd,
    on_stdout = function(_, data)
      table.insert(stdout_results, data)
    end,
    on_stderr = function(_, data)
      table.insert(stderr_results, data)
    end,
    on_exit = vim.schedule_wrap(function(_, code)
      local output = table.concat(stdout_results, "\n")
      local stderr = table.concat(stderr_results, "\n")

      ---@type HaftRunnerResult
      local result = {
        success = code == 0,
        output = output,
        code = code,
        data = nil,
      }

      if opts.json and code == 0 and output ~= "" then
        local parsed = parser.parse_json(output)
        if parsed then
          result.data = parsed
        end
      end

      if code ~= 0 and stderr ~= "" then
        result.output = stderr
      end

      if result.success and opts.on_success then
        opts.on_success(result)
      elseif not result.success and opts.on_error then
        opts.on_error(result)
      end

      if opts.on_complete then
        opts.on_complete(result)
      end
    end),
  }):start()
end

---@param callback fun(version: string?)?
function M.get_version(callback)
  local cfg = config.get()
  local ok, Job = pcall(require, "plenary.job")
  if not ok then
    if callback then
      callback(nil)
    end
    return
  end

  Job:new({
    command = cfg.haft_path,
    args = { "--version" },
    on_exit = vim.schedule_wrap(function(j, code)
      if code ~= 0 then
        if callback then
          callback(nil)
        end
        return
      end

      local output = table.concat(j:result(), "\n")
      local version = output:match("v?(%d+%.%d+%.%d+)")
      if callback then
        callback(version)
      end
    end),
  }):start()
end

---@return string?
function M.get_version_sync()
  local cfg = config.get()
  local result = vim.fn.system({ cfg.haft_path, "--version" })
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return result:match("v?(%d+%.%d+%.%d+)")
end

---@return boolean
function M.is_haft_available()
  local cfg = config.get()
  return vim.fn.executable(cfg.haft_path) == 1
end

return M
