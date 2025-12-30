local config = require("haft.config")

local M = {}

---@type string?
M._cached_root = nil

---@type table?
M._cached_info = nil

---@param path string
---@param pattern string
---@return string?
local function find_root(path, pattern)
  if vim.fs.root then
    return vim.fs.root(path, pattern)
  end

  local current = path
  while current ~= "/" do
    local target = current .. "/" .. pattern
    if vim.fn.filereadable(target) == 1 or vim.fn.isdirectory(target) == 1 then
      return current
    end
    current = vim.fn.fnamemodify(current, ":h")
  end
  return nil
end

---@param path string?
---@return string?
function M.find_project_root(path)
  path = path or vim.fn.getcwd()
  local cfg = config.get()

  if not cfg.detection.enabled then
    return nil
  end

  for _, pattern in ipairs(cfg.detection.patterns) do
    local root = find_root(path, pattern)
    if root then
      return root
    end
  end

  return nil
end

---@return boolean
function M.is_haft_project()
  return M.find_project_root() ~= nil
end

---@return string?
function M.get_project_root()
  if M._cached_root then
    return M._cached_root
  end

  M._cached_root = M.find_project_root()
  return M._cached_root
end

---@return table?
function M.get_project_info()
  local root = M.get_project_root()
  if not root then
    return nil
  end

  if M._cached_info then
    return M._cached_info
  end

  local info = {
    root = root,
    name = vim.fn.fnamemodify(root, ":t"),
    type = M._detect_project_type(root),
  }

  M._cached_info = info
  return info
end

---@param root string
---@return string
function M._detect_project_type(root)
  if vim.fn.filereadable(root .. "/.haft.yaml") == 1 then
    return "haft"
  elseif vim.fn.filereadable(root .. "/pom.xml") == 1 then
    return "maven"
  elseif vim.fn.filereadable(root .. "/build.gradle") == 1 then
    return "gradle"
  elseif vim.fn.filereadable(root .. "/build.gradle.kts") == 1 then
    return "gradle-kts"
  end
  return "unknown"
end

function M.clear_cache()
  M._cached_root = nil
  M._cached_info = nil
end

function M.refresh()
  M.clear_cache()
  return M.get_project_info()
end

return M
