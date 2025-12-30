local config = require("haft.config")

local M = {}

local LEVELS = {
  debug = vim.log.levels.DEBUG,
  info = vim.log.levels.INFO,
  warn = vim.log.levels.WARN,
  error = vim.log.levels.ERROR,
}

---@param msg string
---@param level number
local function notify(msg, level)
  local cfg = config.get()

  if not cfg.notifications.enabled then
    return
  end

  local min_level = LEVELS[cfg.notifications.level] or vim.log.levels.INFO
  if level < min_level then
    return
  end

  vim.notify(msg, level, {
    title = "Haft",
    timeout = cfg.notifications.timeout,
  })
end

---@param msg string
function M.debug(msg)
  notify(msg, vim.log.levels.DEBUG)
end

---@param msg string
function M.info(msg)
  notify(msg, vim.log.levels.INFO)
end

---@param msg string
function M.warn(msg)
  notify(msg, vim.log.levels.WARN)
end

---@param msg string
function M.error(msg)
  notify(msg, vim.log.levels.ERROR)
end

---@param msg string
function M.success(msg)
  notify(msg, vim.log.levels.INFO)
end

return M
