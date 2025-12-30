local M = {}

---@param prompt string
---@param opts table?
---@param callback fun(input: string?)
function M.prompt(prompt, opts, callback)
  opts = opts or {}

  vim.ui.input({
    prompt = prompt,
    default = opts.default or "",
    completion = opts.completion,
  }, function(input)
    if input and input ~= "" then
      callback(input)
    else
      callback(nil)
    end
  end)
end

---@param prompt string
---@param callback fun(confirmed: boolean)
function M.confirm(prompt, callback)
  vim.ui.select({ "Yes", "No" }, {
    prompt = prompt,
  }, function(choice)
    callback(choice == "Yes")
  end)
end

return M
