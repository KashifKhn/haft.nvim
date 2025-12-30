local api = require("haft.api")

local M = {}

function M.setup()
  vim.api.nvim_create_user_command("HaftInfo", function()
    api.info()
  end, { desc = "Show Haft project information" })

  vim.api.nvim_create_user_command("HaftRoutes", function()
    api.routes()
  end, { desc = "Show API routes" })

  vim.api.nvim_create_user_command("HaftStats", function()
    api.stats()
  end, { desc = "Show code statistics" })
end

return M
