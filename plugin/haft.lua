if vim.g.loaded_haft then
  return
end
vim.g.loaded_haft = true

if vim.fn.has("nvim-0.9.0") == 0 then
  vim.api.nvim_err_writeln("haft.nvim requires Neovim >= 0.9.0")
  return
end
