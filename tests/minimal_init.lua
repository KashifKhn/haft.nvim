local function get_plugin_path(name)
  local lazy_path = vim.fn.expand("~/.local/share/nvim/lazy/" .. name)
  if vim.fn.isdirectory(lazy_path) == 1 then
    return lazy_path
  end
  local packer_path = vim.fn.expand("~/.local/share/nvim/site/pack/packer/start/" .. name)
  if vim.fn.isdirectory(packer_path) == 1 then
    return packer_path
  end
  local vendor_path = vim.fn.expand("~/.local/share/nvim/site/pack/vendor/start/" .. name)
  if vim.fn.isdirectory(vendor_path) == 1 then
    return vendor_path
  end
  return nil
end

local plenary_dir = os.getenv("PLENARY_DIR") or get_plugin_path("plenary.nvim")
local telescope_dir = os.getenv("TELESCOPE_DIR") or get_plugin_path("telescope.nvim")

vim.opt.rtp:prepend(".")
if plenary_dir then
  vim.opt.rtp:prepend(plenary_dir)
end
if telescope_dir then
  vim.opt.rtp:prepend(telescope_dir)
end

vim.opt.swapfile = false

if plenary_dir then
  vim.cmd("runtime plugin/plenary.vim")
end
