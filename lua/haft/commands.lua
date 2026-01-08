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

  vim.api.nvim_create_user_command("HaftGenerateException", function(opts)
    local args = opts.args
    if args == "all" then
      api.generate_exception({ all = true })
    elseif args == "default" or args == "defaults" then
      api.generate_exception({ no_interactive = true })
    else
      api.generate_exception({})
    end
  end, { nargs = "?", desc = "Generate global exception handler" })

  vim.api.nvim_create_user_command("HaftGenerateConfig", function(opts)
    local args = opts.args
    if args == "all" then
      api.generate_config({ all = true })
    elseif args == "default" or args == "defaults" then
      api.generate_config({ no_interactive = true })
    else
      api.generate_config({})
    end
  end, { nargs = "?", desc = "Generate configuration classes" })

  vim.api.nvim_create_user_command("HaftGenerateSecurity", function(opts)
    local args = opts.args
    if args == "jwt" then
      api.generate_security({ jwt = true })
    elseif args == "session" then
      api.generate_security({ session = true })
    elseif args == "oauth2" then
      api.generate_security({ oauth2 = true })
    elseif args == "all" then
      api.generate_security({ all = true })
    else
      api.generate_security({})
    end
  end, { nargs = "?", desc = "Generate security configuration" })

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

  vim.api.nvim_create_user_command("HaftInit", function(opts)
    local args = opts.args
    if args == "" then
      api.init()
    elseif args == "tui" then
      api.init_tui()
    elseif args == "wizard" then
      api.init_wizard()
    else
      api.init_quick({ name = args })
    end
  end, { nargs = "?", desc = "Initialize a new Spring Boot project" })

  vim.api.nvim_create_user_command("HaftInitTui", function()
    api.init_tui()
  end, { desc = "Initialize project with TUI wizard" })

  vim.api.nvim_create_user_command("HaftInitWizard", function()
    api.init_wizard()
  end, { desc = "Initialize project with Neovim wizard" })

  vim.api.nvim_create_user_command("HaftInitQuick", function(opts)
    local name = opts.args ~= "" and opts.args or nil
    api.init_quick({ name = name })
  end, { nargs = "?", desc = "Initialize project with defaults (quick mode)" })
end

return M
