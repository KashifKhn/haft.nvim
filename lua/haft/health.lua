local M = {}

function M.check()
  local health = vim.health

  health.start("haft.nvim")

  if vim.fn.has("nvim-0.9.0") == 1 then
    health.ok("Neovim >= 0.9.0")
  else
    health.error("Neovim >= 0.9.0 required", { "Update Neovim to 0.9.0 or later" })
  end

  local runner = require("haft.runner")
  if runner.is_haft_available() then
    local version = runner.get_version_sync()
    if version then
      health.ok("Haft CLI found: v" .. version)
    else
      health.ok("Haft CLI found")
    end
  else
    local config = require("haft.config")
    local cfg = config.get()
    health.error("Haft CLI not found", {
      "Install Haft CLI: https://github.com/KashifKhn/haft",
      "Or set custom path: require('haft').setup({ haft_path = '/path/to/haft' })",
      "Current path: " .. cfg.haft_path,
    })
  end

  local plenary_ok = pcall(require, "plenary")
  if plenary_ok then
    health.ok("plenary.nvim installed")
  else
    health.error("plenary.nvim not found", { "Install: https://github.com/nvim-lua/plenary.nvim" })
  end

  local telescope_ok = pcall(require, "telescope")
  if telescope_ok then
    health.ok("telescope.nvim installed (optional)")
  else
    health.warn("telescope.nvim not found (optional)", {
      "Pickers will use vim.ui.select fallback",
      "Install: https://github.com/nvim-telescope/telescope.nvim",
    })
  end

  local noice_ok = pcall(require, "noice")
  if noice_ok then
    health.ok("noice.nvim installed (optional)")
  else
    health.info("noice.nvim not found (optional)")
  end

  local detection = require("haft.detection")
  if detection.is_haft_project() then
    local info = detection.get_project_info()
    if info then
      health.ok("Haft project detected: " .. info.name .. " (" .. info.type .. ")")
    else
      health.ok("Haft project detected")
    end
  else
    health.info("No Haft project in current directory")
  end
end

return M
