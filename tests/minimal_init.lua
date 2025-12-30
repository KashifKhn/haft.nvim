local plenary_dir = os.getenv("PLENARY_DIR") or vim.fn.expand("~/.local/share/nvim/site/pack/vendor/start/plenary.nvim")
local telescope_dir = os.getenv("TELESCOPE_DIR") or vim.fn.expand("~/.local/share/nvim/site/pack/vendor/start/telescope.nvim")

vim.opt.rtp:prepend(".")
vim.opt.rtp:prepend(plenary_dir)
vim.opt.rtp:prepend(telescope_dir)

vim.opt.swapfile = false

vim.cmd("runtime plugin/plenary.vim")
