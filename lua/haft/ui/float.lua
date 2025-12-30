local config = require("haft.config")

local M = {}

---@class HaftFloatState
---@field bufnr number?
---@field winnr number?

---@type HaftFloatState
M._state = {
  bufnr = nil,
  winnr = nil,
}

---@param opts table?
---@return number, number
local function calculate_dimensions(opts)
  opts = opts or {}
  local cfg = config.get().float

  local width = opts.width or cfg.width
  local height = opts.height or cfg.height

  local editor_width = vim.o.columns
  local editor_height = vim.o.lines - vim.o.cmdheight - 1

  if width <= 1 then
    width = math.floor(editor_width * width)
  end
  if height <= 1 then
    height = math.floor(editor_height * height)
  end

  return math.min(width, editor_width - 4), math.min(height, editor_height - 4)
end

---@param width number
---@param height number
---@return number, number
local function calculate_position(width, height)
  local editor_width = vim.o.columns
  local editor_height = vim.o.lines - vim.o.cmdheight - 1

  local row = math.floor((editor_height - height) / 2)
  local col = math.floor((editor_width - width) / 2)

  return row, col
end

---@param lines string[]
---@param opts table?
---@return number, number
function M.open(lines, opts)
  opts = opts or {}
  local cfg = config.get().float

  M.close()

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].filetype = opts.filetype or "haft"

  local width, height = calculate_dimensions(opts)
  local row, col = calculate_position(width, height)

  local win_opts = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = opts.border or cfg.border,
  }

  if opts.title then
    win_opts.title = " " .. opts.title .. " "
    win_opts.title_pos = opts.title_pos or cfg.title_pos
  end

  local winnr = vim.api.nvim_open_win(bufnr, true, win_opts)

  vim.wo[winnr].wrap = true
  vim.wo[winnr].linebreak = true
  vim.wo[winnr].cursorline = true

  vim.keymap.set("n", "q", function()
    M.close()
  end, { buffer = bufnr, silent = true })

  vim.keymap.set("n", "<Esc>", function()
    M.close()
  end, { buffer = bufnr, silent = true })

  M._state.bufnr = bufnr
  M._state.winnr = winnr

  return bufnr, winnr
end

function M.close()
  if M._state.winnr and vim.api.nvim_win_is_valid(M._state.winnr) then
    vim.api.nvim_win_close(M._state.winnr, true)
  end
  M._state.winnr = nil
  M._state.bufnr = nil
end

---@return boolean
function M.is_open()
  return M._state.winnr ~= nil and vim.api.nvim_win_is_valid(M._state.winnr)
end

---@param lines string[]
function M.update(lines)
  if not M._state.bufnr or not vim.api.nvim_buf_is_valid(M._state.bufnr) then
    return
  end

  vim.bo[M._state.bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(M._state.bufnr, 0, -1, false, lines)
  vim.bo[M._state.bufnr].modifiable = false
end

return M
