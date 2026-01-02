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

  vim.api.nvim_create_user_command("HaftGenerateResource", function(opts)
    local name = opts.args ~= "" and opts.args or nil
    api.generate_resource(name)
  end, { nargs = "?", desc = "Generate a complete CRUD resource" })

  vim.api.nvim_create_user_command("HaftGenerateController", function(opts)
    local name = opts.args ~= "" and opts.args or nil
    api.generate_controller(name)
  end, { nargs = "?", desc = "Generate a REST controller" })

  vim.api.nvim_create_user_command("HaftGenerateService", function(opts)
    local name = opts.args ~= "" and opts.args or nil
    api.generate_service(name)
  end, { nargs = "?", desc = "Generate a service layer" })

  vim.api.nvim_create_user_command("HaftGenerateRepository", function(opts)
    local name = opts.args ~= "" and opts.args or nil
    api.generate_repository(name)
  end, { nargs = "?", desc = "Generate a JPA repository" })

  vim.api.nvim_create_user_command("HaftGenerateEntity", function(opts)
    local name = opts.args ~= "" and opts.args or nil
    api.generate_entity(name)
  end, { nargs = "?", desc = "Generate a JPA entity" })

  vim.api.nvim_create_user_command("HaftGenerateDto", function(opts)
    local name = opts.args ~= "" and opts.args or nil
    api.generate_dto(name)
  end, { nargs = "?", desc = "Generate request/response DTOs" })

  vim.api.nvim_create_user_command("HaftAdd", function(opts)
    local deps = nil
    if opts.args ~= "" then
      deps = vim.split(opts.args, "%s+")
    end
    api.add(deps)
  end, { nargs = "*", desc = "Add dependencies (opens picker if no args)" })

  vim.api.nvim_create_user_command("HaftRemove", function(opts)
    local deps = nil
    if opts.args ~= "" then
      deps = vim.split(opts.args, "%s+")
    end
    api.remove(deps)
  end, { nargs = "*", desc = "Remove dependencies (opens picker if no args)" })
end

return M
