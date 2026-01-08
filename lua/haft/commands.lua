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

  vim.api.nvim_create_user_command("HaftServe", function()
    api.serve()
  end, { desc = "Start dev server with hot-reload" })

  vim.api.nvim_create_user_command("HaftServeStop", function()
    api.serve_stop()
  end, { desc = "Stop the dev server" })

  vim.api.nvim_create_user_command("HaftServeToggle", function()
    api.serve_toggle()
  end, { desc = "Toggle dev server terminal visibility" })

  vim.api.nvim_create_user_command("HaftRestart", function()
    api.restart()
  end, { desc = "Restart the dev server" })

  vim.api.nvim_create_user_command("HaftBuild", function()
    api.build()
  end, { desc = "Build the project" })

  vim.api.nvim_create_user_command("HaftTest", function()
    api.test()
  end, { desc = "Run tests" })

  vim.api.nvim_create_user_command("HaftClean", function()
    api.clean()
  end, { desc = "Clean build artifacts" })

  vim.api.nvim_create_user_command("HaftDeps", function()
    api.deps()
  end, { desc = "Display dependency tree" })

  vim.api.nvim_create_user_command("HaftOutdated", function()
    api.outdated()
  end, { desc = "Check for dependency updates" })

  vim.api.nvim_create_user_command("HaftAutoRestartEnable", function()
    api.enable_auto_restart()
  end, { desc = "Enable auto-restart on file save" })

  vim.api.nvim_create_user_command("HaftAutoRestartDisable", function()
    api.disable_auto_restart()
  end, { desc = "Disable auto-restart on file save" })

  vim.api.nvim_create_user_command("HaftAutoRestartToggle", function()
    api.toggle_auto_restart()
  end, { desc = "Toggle auto-restart on file save" })
end

return M
