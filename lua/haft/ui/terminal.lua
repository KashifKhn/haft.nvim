local config = require("haft.config")

local M = {}

M._terminals = {}

---@class HaftTerminalOpts
---@field cmd string
---@field args string[]?
---@field cwd string?
---@field title string?
---@field on_exit fun(code: number)?

---@param opts HaftTerminalOpts
---@return number?
local function open_float_terminal(opts)
  local cfg = config.get()
  local float_cfg = cfg.terminal.float

  local width = math.floor(vim.o.columns * float_cfg.width)
  local height = math.floor(vim.o.lines * float_cfg.height)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  local buf = vim.api.nvim_create_buf(false, true)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = float_cfg.border,
    title = opts.title or "Haft",
    title_pos = "center",
  })

  vim.api.nvim_set_option_value("winhl", "Normal:Normal,FloatBorder:FloatBorder", { win = win })

  return buf, win
end

---@param opts HaftTerminalOpts
---@return number?
local function open_split_terminal(opts)
  local cfg = config.get()
  local split_cfg = cfg.terminal.split

  local cmd = split_cfg.position == "below" and "botright" or "topleft"
  cmd = cmd .. " " .. split_cfg.size .. "split"
  vim.cmd(cmd)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, buf)

  return buf, vim.api.nvim_get_current_win()
end

---@param id string
---@param opts HaftTerminalOpts
function M.open(id, opts)
  local cfg = config.get()

  if cfg.terminal.persist and M._terminals[id] then
    local term = M._terminals[id]
    if vim.api.nvim_buf_is_valid(term.buf) then
      if term.win and vim.api.nvim_win_is_valid(term.win) then
        vim.api.nvim_set_current_win(term.win)
        return
      else
        local win
        if cfg.terminal.type == "float" then
          win = select(2, open_float_terminal(opts))
          vim.api.nvim_win_set_buf(win, term.buf)
        else
          win = select(2, open_split_terminal(opts))
          vim.api.nvim_win_set_buf(win, term.buf)
        end
        term.win = win
        return
      end
    end
  end

  local buf, win
  local term_type = cfg.terminal.type

  if term_type == "auto" then
    term_type = vim.o.columns > 120 and "split" or "float"
  end

  if term_type == "float" then
    buf, win = open_float_terminal(opts)
  else
    buf, win = open_split_terminal(opts)
  end

  local full_cmd = opts.cmd
  if opts.args and #opts.args > 0 then
    full_cmd = full_cmd .. " " .. table.concat(opts.args, " ")
  end

  local term_opts = {
    cwd = opts.cwd,
    on_exit = function(_, code)
      if cfg.terminal.auto_close and code == 0 then
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_delete(buf, { force = true })
          end
          M._terminals[id] = nil
        end)
      end
      if opts.on_exit then
        vim.schedule(function()
          opts.on_exit(code)
        end)
      end
    end,
  }

  local job_id = vim.fn.termopen(full_cmd, term_opts)

  M._terminals[id] = {
    buf = buf,
    win = win,
    job_id = job_id,
  }

  vim.cmd("startinsert")

  vim.keymap.set("t", "q", function()
    M.close(id)
  end, { buffer = buf, noremap = true, silent = true })

  vim.keymap.set("t", "<Esc><Esc>", function()
    vim.cmd("stopinsert")
  end, { buffer = buf, noremap = true, silent = true })
end

---@param id string
function M.close(id)
  local term = M._terminals[id]
  if not term then
    return
  end

  if term.job_id and vim.fn.jobwait({ term.job_id }, 0)[1] == -1 then
    vim.fn.jobstop(term.job_id)
  end

  if term.buf and vim.api.nvim_buf_is_valid(term.buf) then
    vim.api.nvim_buf_delete(term.buf, { force = true })
  end

  M._terminals[id] = nil
end

---@param id string
function M.toggle(id)
  local term = M._terminals[id]
  if term and term.win and vim.api.nvim_win_is_valid(term.win) then
    vim.api.nvim_win_hide(term.win)
    term.win = nil
  elseif term and term.buf and vim.api.nvim_buf_is_valid(term.buf) then
    local cfg = config.get()
    local term_type = cfg.terminal.type
    if term_type == "auto" then
      term_type = vim.o.columns > 120 and "split" or "float"
    end

    local win
    if term_type == "float" then
      win = select(2, open_float_terminal({ title = "Haft" }))
      vim.api.nvim_win_set_buf(win, term.buf)
    else
      win = select(2, open_split_terminal({}))
      vim.api.nvim_win_set_buf(win, term.buf)
    end
    term.win = win
    vim.cmd("startinsert")
  end
end

---@param id string
---@return boolean
function M.is_running(id)
  local term = M._terminals[id]
  if not term or not term.job_id then
    return false
  end
  return vim.fn.jobwait({ term.job_id }, 0)[1] == -1
end

---@param id string
function M.stop(id)
  local term = M._terminals[id]
  if term and term.job_id then
    vim.fn.jobstop(term.job_id)
  end
end

---@param id string
---@param data string
function M.send(id, data)
  local term = M._terminals[id]
  if term and term.job_id then
    vim.fn.chansend(term.job_id, data)
  end
end

function M.close_all()
  for id, _ in pairs(M._terminals) do
    M.close(id)
  end
end

return M
